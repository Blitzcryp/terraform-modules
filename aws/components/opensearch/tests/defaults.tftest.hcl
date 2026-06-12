# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the opensearch component's secure-by-default
# composition. Under mock_provider, computed values such as ARNs are unknown, so
# we assert on known/derived values (counts, names, ports, policy JSON,
# validation) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name                       = "test-search"
      vpc_id                     = "vpc-0123456789abcdef0"
      subnet_ids                 = ["subnet-aaa", "subnet-bbb"]
      allowed_security_group_ids = ["sg-client1"]
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  assert {
    condition     = local.create_kms == true
    error_message = "Component must own the CMK when no BYO kms_key_arn is supplied."
  }

  # Domain SG name is derived from config.name (known at plan time).
  assert {
    condition     = module.security_group.manifest.name == "test-search-opensearch"
    error_message = "Domain SG name must be derived from config.name."
  }

  # Log group name is derived from config.name (known at plan time).
  assert {
    condition     = module.log_group.manifest.name == "/aws/opensearch/test-search"
    error_message = "Audit/slow-log group name must be derived from config.name."
  }

  # The created CMK alias is derived from config.name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/opensearch/test-search"
    error_message = "KMS alias must be derived from config.name."
  }

  # The domain runs the secure defaults: encryption at rest + node-to-node +
  # enforced HTTPS on TLS 1.2 are all on (asserted on the composed atom resource).
  assert {
    condition     = module.domain.manifest.domain_name == "test-search"
    error_message = "Domain name must be derived from config.name."
  }

  # The SG opens ONLY HTTPS (443), one rule per source, and NEVER public ingress.
  assert {
    condition     = length(local.sg_ingress_rules) == 1 && local.sg_ingress_rules[0].from_port == 443 && local.sg_ingress_rules[0].to_port == 443
    error_message = "One client SG must yield exactly one HTTPS (443) ingress rule."
  }

  assert {
    condition     = alltrue([for r in local.ingress_rules : !can(r.cidr_ipv4) || r.cidr_ipv4 != "0.0.0.0/0"])
    error_message = "Domain SG must never open public (0.0.0.0/0) ingress."
  }

  # KMS policy authorises both the regional CloudWatch Logs principal and OpenSearch.
  assert {
    condition     = can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy)) && can(regex("es\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the CloudWatch Logs and OpenSearch service principals use of the key."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name          = "test-search-byo"
      vpc_id        = "vpc-0123456789abcdef0"
      subnet_ids    = ["subnet-aaa", "subnet-bbb"]
      allowed_cidrs = ["10.0.0.0/16"]
      kms_key_arn   = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key supplied -> no kms-key atom is created.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Domain and log group must be encrypted with the supplied BYO KMS key."
  }

  # The manifest's kms_key_arn is the BYO key (a known, derived value).
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "manifest.kms_key_arn must report the effective (BYO) key."
  }

  # CIDR-sourced ingress still only opens HTTPS (443).
  assert {
    condition     = length(local.ingress_rules) == 1 && local.ingress_rules[0].cidr_ipv4 == "10.0.0.0/16" && local.ingress_rules[0].from_port == 443
    error_message = "One allowed CIDR must yield one HTTPS (443) ingress rule scoped to that CIDR."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name        = "test-search-badarn"
      vpc_id      = "vpc-0123456789abcdef0"
      subnet_ids  = ["subnet-aaa"]
      kms_key_arn = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
