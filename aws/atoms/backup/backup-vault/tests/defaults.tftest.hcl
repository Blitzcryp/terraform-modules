# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider, computed values such as ARNs are unknown, so we
# assert on known/derived values (counts, names, args, validation, preconditions)
# rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name        = "test-vault"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # Vault is encrypted with the supplied customer-managed CMK.
  assert {
    condition     = aws_backup_vault.this.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Vault must be encrypted with the supplied customer-managed KMS key."
  }

  # Vault Lock is off by default.
  assert {
    condition     = length(aws_backup_vault_lock_configuration.this) == 0
    error_message = "Vault Lock must be off by default (enable_lock defaults to false)."
  }

  # The atom echoes its name (known at plan time even under the mock provider).
  assert {
    condition     = aws_backup_vault.this.name == "test-vault"
    error_message = "Vault name must be derived from config.name."
  }
}

run "compliance_mode_lock_sets_cooling_off_window" {
  command = plan

  variables {
    config = {
      name                = "test-vault-locked"
      kms_key_arn         = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      enable_lock         = true
      lock_mode           = "compliance"
      min_retention_days  = 35
      max_retention_days  = 365
      changeable_for_days = 7
    }
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.this) == 1
    error_message = "Vault Lock must be rendered when enable_lock = true."
  }

  # Compliance mode is selected by passing changeable_for_days (the cooling-off
  # window); this is what makes the lock immutable (WORM, PCI DSS Req 10.5 / 12).
  assert {
    condition     = aws_backup_vault_lock_configuration.this[0].changeable_for_days == 7
    error_message = "Compliance-mode lock must set changeable_for_days (cooling-off window)."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.this[0].min_retention_days == 35
    error_message = "Vault Lock must enforce min_retention_days."
  }
}

run "governance_mode_lock_omits_cooling_off_window" {
  command = plan

  variables {
    config = {
      name        = "test-vault-gov"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      enable_lock = true
      # lock_mode defaults to governance
    }
  }

  # Governance mode omits changeable_for_days so the lock is not immutable.
  assert {
    condition     = aws_backup_vault_lock_configuration.this[0].changeable_for_days == null
    error_message = "Governance-mode lock must omit changeable_for_days."
  }
}

run "unencrypted_vault_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name = "test-vault-unencrypted"
      # kms_key_arn omitted, allow_unencrypted left at its false default
    }
  }

  expect_failures = [
    aws_backup_vault.this,
  ]
}

run "lock_mode_validation_rejects_invalid_value" {
  command = plan

  variables {
    config = {
      name        = "test-vault-badmode"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      lock_mode   = "immutable"
    }
  }

  expect_failures = [
    var.config,
  ]
}
