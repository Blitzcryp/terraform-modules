# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs are unknown, so we
# assert on known/derived values (counts, names, policy JSON, validation) and on
# plan success rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name_prefix = "test-audit"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Flow-log role requested by default.
  assert {
    condition     = length(module.flow_log_role) == 1
    error_message = "The flow-log role must be created by default (create_flow_log_role defaults to true)."
  }

  # Log group name is derived from name_prefix (the atom echoes its input name,
  # which is known at plan time even under the mock provider).
  assert {
    condition     = module.log_group.manifest.name == "/test-audit/audit"
    error_message = "Log group name must be derived from config.name_prefix."
  }

  # The created CMK's alias is derived from name_prefix (known at plan time).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/test-audit/audit"
    error_message = "KMS alias must be derived from config.name_prefix."
  }

  # The KMS policy this component builds must authorise the regional CloudWatch
  # Logs service principal (apply-time correctness for CMK-encrypted log groups).
  assert {
    condition     = can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the CloudWatch Logs service principal use of the key."
  }

  # The flow-log delivery policy must be scoped to this component's log group
  # (least privilege, PCI DSS Req 7) and grant the required log actions.
  assert {
    condition     = can(regex("logs:PutLogEvents", local.flow_log_inline_policy)) && can(regex("/test-audit/audit", local.flow_log_inline_policy))
    error_message = "Flow-log inline policy must allow PutLogEvents scoped to the component log group."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name_prefix = "test-audit-byo"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key supplied -> no kms-key atom is created.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  # The component reports the BYO key as the effective encryption key, and marks
  # the created-only fields null (we did not create the key).
  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Log group must be encrypted with the supplied BYO KMS key."
  }

  assert {
    condition     = output.manifest.kms_key_id == null && output.manifest.kms_alias_arn == null
    error_message = "kms_key_id and kms_alias_arn must be null when a BYO key is used."
  }
}

run "no_flow_log_role_when_disabled" {
  command = plan

  variables {
    config = {
      name_prefix          = "test-audit-norole"
      create_flow_log_role = false
    }
  }

  assert {
    condition     = length(module.flow_log_role) == 0
    error_message = "No flow-log role must be created when create_flow_log_role = false."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name_prefix = "test-audit-badarn"
      kms_key_arn = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
