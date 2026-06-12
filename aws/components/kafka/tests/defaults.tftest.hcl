# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the kafka component's secure-by-default
# composition. Under mock_provider, computed values such as ARNs are unknown, so
# we assert on known/derived values (counts, names, ports, policy JSON,
# validation) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name                       = "test-kafka"
      vpc_id                     = "vpc-0123456789abcdef0"
      client_subnets             = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
      allowed_security_group_ids = ["sg-client1"]
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Exactly one SG, one log group and one MSK cluster are composed.
  assert {
    condition     = module.security_group.manifest.name == "test-kafka-msk"
    error_message = "Broker SG name must be derived from config.name."
  }

  # Log group name is derived from config.name (known at plan time).
  assert {
    condition     = module.log_group.manifest.name == "/aws/msk/test-kafka"
    error_message = "Broker log group name must be derived from config.name."
  }

  # The created CMK alias is derived from config.name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/msk/test-kafka"
    error_message = "KMS alias must be derived from config.name."
  }

  # The SG opens the Kafka TLS ports (9094 + 9098), one rule per source x port,
  # and NEVER a public 0.0.0.0/0 rule.
  assert {
    condition     = length(local.sg_ingress_rules) == 2
    error_message = "One client SG must yield exactly two ingress rules (TLS 9094 + SASL/IAM 9098)."
  }

  assert {
    condition     = alltrue([for r in local.sg_ingress_rules : contains([9094, 9098], r.from_port)])
    error_message = "Broker SG must only open Kafka TLS ports 9094 and 9098."
  }

  assert {
    condition     = alltrue([for r in local.sg_ingress_rules : !can(r.cidr_ipv4) || r.cidr_ipv4 != "0.0.0.0/0"])
    error_message = "Broker SG must never open public (0.0.0.0/0) ingress."
  }

  # KMS policy authorises both the regional CloudWatch Logs principal and MSK.
  assert {
    condition     = can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy)) && can(regex("kafka\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the CloudWatch Logs and MSK service principals use of the key."
  }

  # The component owns the CMK (effective ARN comes from the created atom, not a
  # BYO key). The ARN itself is unknown under mock, so we assert the branch.
  assert {
    condition     = local.create_kms == true
    error_message = "Component must own the CMK when no BYO kms_key_arn is supplied."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name           = "test-kafka-byo"
      vpc_id         = "vpc-0123456789abcdef0"
      client_subnets = ["subnet-aaa", "subnet-bbb"]
      allowed_cidrs  = ["10.0.0.0/16"]
      kms_key_arn    = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key supplied -> no kms-key atom is created.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Cluster and log group must be encrypted with the supplied BYO KMS key."
  }

  # The manifest's kms_key_arn is the BYO key (a known, derived value).
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "manifest.kms_key_arn must report the effective (BYO) key."
  }

  # CIDR-sourced ingress still only opens the Kafka TLS ports.
  assert {
    condition     = length(local.sg_ingress_rules) == 2 && alltrue([for r in local.sg_ingress_rules : r.cidr_ipv4 == "10.0.0.0/16"])
    error_message = "One allowed CIDR must yield two TLS-port ingress rules scoped to that CIDR."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name           = "test-kafka-badarn"
      vpc_id         = "vpc-0123456789abcdef0"
      client_subnets = ["subnet-aaa"]
      kms_key_arn    = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
