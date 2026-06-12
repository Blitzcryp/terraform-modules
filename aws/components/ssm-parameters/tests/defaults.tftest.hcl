# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs are unknown under the mock provider, so assertions target known/derived
# values (module counts, derived names, the manifest) plus plan success. The
# config is sensitive (it carries parameter values), so config-derived values
# are wrapped in nonsensitive(). No real secret values appear anywhere — only a
# placeholder string.

mock_provider "aws" {}

run "secure_defaults_create_cmk_and_parameters" {
  command = plan

  variables {
    config = {
      name_prefix = "/emag/payments"
      parameters = {
        "db-password" = { value = "<YOUR_PARAMETER_VALUE>" }
        "api-token"   = { value = "<YOUR_PARAMETER_VALUE>" }
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
    condition     = module.kms_key[0].manifest.alias_name == "alias/ssm//emag/payments"
    error_message = "KMS alias must be derived as alias/ssm/<name_prefix>."
  }

  # One parameter atom per entry in the parameters map.
  assert {
    condition     = length(module.parameter) == 2
    error_message = "One parameter atom must be created per entry in config.parameters."
  }

  # Full parameter name is derived as <name_prefix>/<key>.
  assert {
    condition     = nonsensitive(module.parameter["db-password"].manifest.name) == "/emag/payments/db-password"
    error_message = "Parameter name must be derived as <name_prefix>/<key>."
  }

  # The manifest exposes a parameter_arns map keyed by the logical name.
  assert {
    condition     = length(keys(nonsensitive(output.manifest.parameter_arns))) == 2 && contains(keys(nonsensitive(output.manifest.parameter_arns)), "api-token")
    error_message = "manifest.parameter_arns must be keyed by the logical parameter names."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      name_prefix = "/emag/payments"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      parameters = {
        "db-password" = { value = "<YOUR_PARAMETER_VALUE>" }
      }
    }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when config.kms_key_arn is supplied."
  }

  assert {
    condition     = nonsensitive(output.manifest.kms_key_arn) == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "manifest.kms_key_arn must be the supplied BYOK ARN."
  }
}

run "empty_parameters_map_creates_only_cmk" {
  command = plan

  variables {
    config = {
      name_prefix = "/emag/payments"
    }
  }

  assert {
    condition     = length(module.parameter) == 0
    error_message = "No parameter atoms must be created when config.parameters is empty."
  }

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "The CMK atom must still be created with an empty parameters map."
  }
}

# --- Negative: invalid parameter key -> config validation fails. ---
run "invalid_parameter_key_is_rejected" {
  command = plan

  variables {
    config = {
      name_prefix = "/emag/payments"
      parameters = {
        "bad key!" = { value = "<YOUR_PARAMETER_VALUE>" }
      }
    }
  }

  expect_failures = [
    var.config,
  ]
}
