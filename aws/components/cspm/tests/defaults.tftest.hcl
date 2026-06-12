# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs/ids are unknown, so we
# assert on known/derived values (module counts, derived names, the Config bucket
# policy JSON, manifest nullness) and on plan success rather than computed ARNs.

mock_provider "aws" {}

# Pin region/partition so derived ARNs (Config bucket policy, managed policy,
# Security Hub standards) are valid under the mock provider.
override_data {
  target = data.aws_region.current
  values = { name = "eu-central-1" }
}
override_data {
  target = data.aws_partition.current
  values = { partition = "aws" }
}
override_data {
  target = data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

run "secure_defaults_compose_all_capabilities" {
  command = plan

  variables {
    config = {
      name_prefix = "test-cspm"
    }
  }

  # The Security Hub atom builds region/partition-aware standard ARNs and the
  # Inspector atom reads its own caller identity; pin both child modules' data
  # sources so the generated values are valid under the mock provider.
  override_data {
    target = module.security_hub[0].data.aws_region.current
    values = { name = "eu-central-1" }
  }
  override_data {
    target = module.security_hub[0].data.aws_partition.current
    values = { partition = "aws" }
  }
  override_data {
    target = module.inspector[0].data.aws_caller_identity.current
    values = { account_id = "111122223333" }
  }

  # All four capabilities enabled by default -> one of each atom (the Config
  # capability also creates its bucket + role + recorder).
  assert {
    condition     = length(module.security_hub) == 1
    error_message = "Security Hub must be enabled by default."
  }
  assert {
    condition     = length(module.config_recorder) == 1 && length(module.config_bucket) == 1 && length(module.config_role) == 1
    error_message = "AWS Config (recorder + bucket + role) must be enabled by default."
  }
  assert {
    condition     = length(module.guardduty) == 1
    error_message = "GuardDuty must be enabled by default."
  }
  assert {
    condition     = length(module.inspector) == 1
    error_message = "Inspector must be enabled by default."
  }

  # No BYO key -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Config delivery bucket name is derived (account id known via override).
  assert {
    condition     = module.config_bucket[0].manifest.bucket == "test-cspm-config-111122223333"
    error_message = "Config bucket name must be derived from name_prefix + account id."
  }

  # The CMK alias is derived from name_prefix (known at plan time).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/test-cspm/cspm"
    error_message = "KMS alias must be derived from config.name_prefix."
  }

  # APPLY-TIME: the Config bucket policy must authorise the AWS Config service
  # principal to write delivery objects (else the channel fails at apply).
  assert {
    condition     = can(regex("config\\.amazonaws\\.com", jsonencode(local.config_bucket_policy_statements))) && can(regex("s3:PutObject", jsonencode(local.config_bucket_policy_statements)))
    error_message = "Config bucket policy must grant the AWS Config service principal s3:PutObject."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name_prefix = "test-cspm-byo"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  override_data {
    target = module.security_hub[0].data.aws_region.current
    values = { name = "eu-central-1" }
  }
  override_data {
    target = module.security_hub[0].data.aws_partition.current
    values = { partition = "aws" }
  }
  override_data {
    target = module.inspector[0].data.aws_caller_identity.current
    values = { account_id = "111122223333" }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The component must report the BYO key as the effective CMK."
  }
}

run "disabled_capabilities_gate_atoms_and_null_manifest" {
  command = plan

  variables {
    config = {
      name_prefix         = "test-cspm-off"
      enable_security_hub = false
      enable_config       = false
      enable_guardduty    = false
      enable_inspector    = false
    }
  }

  assert {
    condition     = length(module.security_hub) == 0 && length(module.config_recorder) == 0 && length(module.guardduty) == 0 && length(module.inspector) == 0
    error_message = "Disabled capabilities must create no atoms."
  }

  assert {
    condition     = length(module.config_bucket) == 0 && length(module.config_role) == 0
    error_message = "Disabling Config must skip its bucket and role too."
  }

  # Disabled capabilities surface null in the manifest.
  assert {
    condition     = output.manifest.security_hub_account_id == null && output.manifest.config_recorder_name == null && output.manifest.guardduty_detector_id == null && output.manifest.inspector_id == null && output.manifest.config_bucket_arn == null
    error_message = "Manifest keys for disabled capabilities must be null."
  }
}

# Negative case: an invalid inspector resource type is rejected by validation.
run "invalid_inspector_type_is_rejected" {
  command = plan

  variables {
    config = {
      name_prefix              = "test-cspm-bad"
      inspector_resource_types = ["EC2", "RDS"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
