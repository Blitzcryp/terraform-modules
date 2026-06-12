# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids are unknown under the mock provider, so assertions target known and
# derived values (module counts, derived names, the component manifest) plus
# overall plan success.

mock_provider "aws" {}

run "secure_defaults_create_cmk_and_secrets" {
  command = plan

  variables {
    config = {
      name_prefix = "emag/payments"
      secrets = {
        "db-password" = { description = "Payments DB creds" }
        "api-token"   = {}
      }
    }
  }

  # A dedicated CMK atom is created when no BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when config.kms_key_arn is null."
  }

  # CMK alias is derived from the name_prefix.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/secretsmanager/emag/payments"
    error_message = "KMS alias must be derived as alias/secretsmanager/<name_prefix>."
  }

  # One secret atom per entry in the secrets map.
  assert {
    condition     = length(module.secret) == 2
    error_message = "One secret atom must be created per entry in config.secrets."
  }

  # Full secret name is derived as <name_prefix>/<key>.
  assert {
    condition     = module.secret["db-password"].manifest.secret_name == "emag/payments/db-password"
    error_message = "Secret name must be derived as <name_prefix>/<key>."
  }

  # The manifest exposes a secret_arns map keyed by the logical name.
  assert {
    condition     = length(keys(output.manifest.secret_arns)) == 2 && contains(keys(output.manifest.secret_arns), "api-token")
    error_message = "manifest.secret_arns must be keyed by the logical secret names."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      name_prefix = "emag/payments"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      secrets = {
        "db-password" = {}
      }
    }
  }

  # No KMS atom created when a BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when config.kms_key_arn is supplied."
  }

  # The supplied ARN flows through to the manifest; kms_key_id is null (BYOK).
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "manifest.kms_key_arn must be the supplied BYOK ARN."
  }

  assert {
    condition     = output.manifest.kms_key_id == null
    error_message = "manifest.kms_key_id must be null when the key is BYOK."
  }
}

run "empty_secrets_map_creates_only_cmk" {
  command = plan

  variables {
    config = {
      name_prefix = "emag/payments"
    }
  }

  assert {
    condition     = length(module.secret) == 0
    error_message = "No secret atoms must be created when config.secrets is empty."
  }

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "The CMK atom must still be created with an empty secrets map."
  }
}

# --- Negative case: out-of-range recovery window is rejected by config validation. ---
run "recovery_window_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      name_prefix             = "emag/payments"
      recovery_window_in_days = 3
    }
  }

  expect_failures = [
    var.config,
  ]
}
