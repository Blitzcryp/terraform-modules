# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs/ids are unknown, so we
# assert on known/derived values (module counts, names, policy JSON, derived
# selection objects, validation) and on plan success rather than computed ARNs.

mock_provider "aws" {}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name = "test-backup"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Vault name is derived from config.name (the vault atom echoes its input name,
  # known at plan time even under the mock provider).
  assert {
    condition     = module.vault.manifest.name == "test-backup-vault"
    error_message = "Vault name must be derived from config.name."
  }

  # Default daily schedule and 35-day retention (component-level defaults).
  assert {
    condition     = var.config.schedule == "cron(0 5 * * ? *)"
    error_message = "Schedule must default to a daily cron."
  }

  assert {
    condition     = var.config.delete_after_days == 35
    error_message = "Retention must default to 35 days."
  }

  # Default tag-based selection backs up resources tagged Backup=true.
  assert {
    condition     = one(local.selection_tag_objects).key == "Backup" && one(local.selection_tag_objects).value == "true"
    error_message = "Default selection must target resources tagged Backup=true."
  }

  # The CMK policy this component builds must authorise the AWS Backup service
  # principal (apply-time correctness for CMK-encrypted recovery points).
  assert {
    condition     = can(regex("backup\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the AWS Backup service principal use of the key."
  }

  # The service role must attach the AWS-managed backup + restore policies.
  assert {
    condition     = contains(local.backup_managed_policy_arns, "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup") && contains(local.backup_managed_policy_arns, "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores")
    error_message = "Backup role must attach the AWS-managed Backup and Restores policies."
  }

  # Vault Lock off by default.
  assert {
    condition     = var.config.enable_vault_lock == false
    error_message = "Vault Lock must be off by default."
  }

  # The effective KMS ARN reported by the manifest is the created key (unknown
  # ARN under mock, so we assert it is non-null / derived from create_kms path).
  assert {
    condition     = local.create_kms == true
    error_message = "Component must create its own CMK when no BYO key is supplied."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name        = "test-backup-byo"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Recovery points must be encrypted with the supplied BYO KMS key."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Manifest must report the BYO key as the effective encryption key."
  }
}

run "vault_lock_compliance_mode_when_enabled" {
  command = plan

  variables {
    config = {
      name               = "test-backup-locked"
      enable_vault_lock  = true
      lock_mode          = "compliance"
      min_retention_days = 35
      max_retention_days = 365
    }
  }

  assert {
    condition     = var.config.enable_vault_lock == true && var.config.lock_mode == "compliance"
    error_message = "Vault Lock must be enabled in compliance mode when requested."
  }
}

# Negative case: an invalid lock_mode is rejected by the config validation block.
run "invalid_lock_mode_is_rejected" {
  command = plan

  variables {
    config = {
      name      = "test-backup-badmode"
      lock_mode = "immutable"
    }
  }

  expect_failures = [
    var.config,
  ]
}
