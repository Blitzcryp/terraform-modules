# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the mq component's secure-by-default
# composition. The config carries broker passwords and is marked sensitive, so
# derived values are tainted sensitive; we wrap assertions in nonsensitive().
# Under mock_provider, computed values such as ARNs are unknown, so we assert on
# known/derived values (counts, names, ports, validation) and on plan success.
#
# NOTE: the test password below is a non-credential placeholder for plan-time
# validation only — never a real secret (PCI DSS Req 8).

mock_provider "aws" {}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      broker_name                = "test-mq"
      vpc_id                     = "vpc-0123456789abcdef0"
      subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
      allowed_security_group_ids = ["sg-client1"]
      users = [
        { username = "admin", password = "<YOUR_BROKER_PASSWORD>", console_access = true },
      ]
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Broker SG name is derived from broker_name (known at plan time).
  assert {
    condition     = nonsensitive(module.security_group.manifest.name) == "test-mq-mq"
    error_message = "Broker SG name must be derived from config.broker_name."
  }

  # The created CMK alias is derived from broker_name.
  assert {
    condition     = nonsensitive(module.kms_key[0].manifest.alias_name) == "alias/mq/test-mq"
    error_message = "KMS alias must be derived from config.broker_name."
  }

  # ActiveMQ (default) opens OpenWire SSL 61617 + console SSL 8162, one rule per
  # source x port, and NEVER public 0.0.0.0/0 ingress.
  assert {
    condition     = length(local.sg_ingress_rules) == 2
    error_message = "One client SG must yield two ActiveMQ TLS-port ingress rules (61617 + 8162)."
  }

  assert {
    condition     = alltrue([for r in local.sg_ingress_rules : contains([61617, 8162], r.from_port)])
    error_message = "ActiveMQ broker SG must only open TLS ports 61617 and 8162."
  }

  assert {
    condition     = alltrue([for r in local.sg_ingress_rules : !can(r.cidr_ipv4) || r.cidr_ipv4 != "0.0.0.0/0"])
    error_message = "Broker SG must never open public (0.0.0.0/0) ingress."
  }

  # The component owns the CMK (effective ARN comes from the created atom, not a
  # BYO key). The ARN itself is unknown under mock, so we assert the branch.
  assert {
    condition     = local.create_kms == true
    error_message = "Component must own the CMK when no BYO kms_key_arn is supplied."
  }
}

run "rabbitmq_opens_amqps_and_byo_key_skips_kms" {
  command = plan

  variables {
    config = {
      broker_name   = "test-mq-rabbit"
      vpc_id        = "vpc-0123456789abcdef0"
      subnet_ids    = ["subnet-aaa"]
      engine_type   = "RabbitMQ"
      allowed_cidrs = ["10.0.0.0/16"]
      kms_key_arn   = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      users = [
        { username = "admin", password = "<YOUR_BROKER_PASSWORD>" },
      ]
    }
  }

  # BYO key supplied -> no kms-key atom is created.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Broker must be encrypted with the supplied BYO KMS key."
  }

  # manifest reports the BYO key (known, derived value).
  assert {
    condition     = nonsensitive(output.manifest.kms_key_arn) == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "manifest.kms_key_arn must report the effective (BYO) key."
  }

  # RabbitMQ opens only AMQPS 5671, scoped to the supplied CIDR.
  assert {
    condition     = length(local.sg_ingress_rules) == 1 && local.sg_ingress_rules[0].from_port == 5671 && local.sg_ingress_rules[0].cidr_ipv4 == "10.0.0.0/16"
    error_message = "RabbitMQ broker SG must open AMQPS 5671 scoped to the allowed CIDR."
  }
}

# Negative case: empty users list is rejected by the config validation block.
run "empty_users_is_rejected" {
  command = plan

  variables {
    config = {
      broker_name = "test-mq-nousers"
      vpc_id      = "vpc-0123456789abcdef0"
      subnet_ids  = ["subnet-aaa"]
      users       = []
    }
  }

  expect_failures = [
    var.config,
  ]
}
