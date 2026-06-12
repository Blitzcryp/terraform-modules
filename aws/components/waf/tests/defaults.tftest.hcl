# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs are unknown, so we
# assert on known/derived values (counts, names, policy JSON, manifest nullness)
# and on plan success rather than on computed ARNs.

mock_provider "aws" {}

# The log-destination ARN is built from the account ID and region (read via data
# sources). Under the mock provider these are random strings that fail the
# provider-side WAFv2 ARN validation, so we pin valid values.
override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "111122223333"
  }
}

override_data {
  target = data.aws_region.current
  values = {
    name = "eu-central-1"
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name = "test-waf"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # No associations requested by default.
  assert {
    condition     = length(module.associations) == 0
    error_message = "No association atoms must be created when associate_resource_arns is empty."
  }

  # The log group name MUST carry the reserved WAFv2 logging prefix (known at
  # plan time — the atom echoes its input name).
  assert {
    condition     = module.log_group.manifest.name == "aws-waf-logs-test-waf"
    error_message = "WAF log group name must start with the reserved aws-waf-logs- prefix."
  }

  # The created CMK's alias is derived from the name (known at plan time).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/waf/test-waf"
    error_message = "KMS alias must be derived from config.name."
  }

  # The KMS policy must authorise the regional CloudWatch Logs service principal
  # (apply-time correctness for CMK-encrypted log groups).
  assert {
    condition     = can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the CloudWatch Logs service principal use of the key."
  }

  # Manifest collects the (computed) association list as empty by default.
  assert {
    condition     = length(output.manifest.association_ids) == 0
    error_message = "association_ids must be empty when no resources are associated."
  }
}

run "associations_created_per_resource_arn" {
  command = plan

  variables {
    config = {
      name = "test-waf-assoc"
      associate_resource_arns = [
        "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/a/0123456789abcdef",
        "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/b/fedcba9876543210",
      ]
    }
  }

  assert {
    condition     = length(module.associations) == 2
    error_message = "One association atom must be created per associate_resource_arns entry."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name        = "test-waf-byo"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The log group must be encrypted with the supplied BYO KMS key."
  }
}

# Negative (validation -> var.config): CLOUDFRONT scope cannot carry regional
# associations.
run "cloudfront_with_associations_is_rejected" {
  command = plan

  variables {
    config = {
      name                    = "test-waf-cf"
      scope                   = "CLOUDFRONT"
      associate_resource_arns = ["arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/a/0123456789abcdef"]
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative (precondition -> resource): a retention shorter than the component
# minimum is blocked by the retention guard (PCI DSS Req 10.5.1).
run "short_retention_is_blocked_by_precondition" {
  command = plan

  variables {
    config = {
      name               = "test-waf-shortret"
      log_retention_days = 30
    }
  }

  expect_failures = [
    terraform_data.retention_guard,
  ]
}
