# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour. The
# config is sensitive (it carries the parameter value), so assertions that touch
# config-derived values wrap them in nonsensitive(). No real secret values are
# used anywhere — only a placeholder string.

mock_provider "aws" {}

run "secure_defaults_securestring_with_cmk" {
  command = plan

  variables {
    config = {
      name        = "/app/db-password"
      value       = "<YOUR_PARAMETER_VALUE>"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # Defaults to SecureString.
  assert {
    condition     = nonsensitive(aws_ssm_parameter.this.type) == "SecureString"
    error_message = "Parameter type must default to SecureString (PCI DSS Req 3)."
  }

  # SecureString is encrypted with the supplied CMK via key_id.
  assert {
    condition     = nonsensitive(aws_ssm_parameter.this.key_id) == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "SecureString must be encrypted with the supplied customer-managed key."
  }

  # Tier defaults to Standard.
  assert {
    condition     = nonsensitive(aws_ssm_parameter.this.tier) == "Standard"
    error_message = "Tier must default to Standard."
  }

  # Manifest exposes the derived name.
  assert {
    condition     = nonsensitive(output.manifest.name) == "/app/db-password"
    error_message = "manifest.name must equal the configured parameter name."
  }
}

run "plaintext_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name            = "/app/feature-flag"
      value           = "enabled"
      type            = "String"
      allow_plaintext = true
    }
  }

  assert {
    condition     = nonsensitive(aws_ssm_parameter.this.type) == "String"
    error_message = "Plaintext String must be permitted when allow_plaintext is true."
  }
}

# --- Negative: plaintext without the escape hatch -> precondition fails. ---
run "plaintext_without_escape_hatch_is_blocked" {
  command = plan

  variables {
    config = {
      name  = "/app/feature-flag"
      value = "enabled"
      type  = "String"
      # allow_plaintext left at its false default
    }
  }

  expect_failures = [
    aws_ssm_parameter.this,
  ]
}

# --- Negative: invalid type -> config validation fails. ---
run "invalid_type_is_rejected" {
  command = plan

  variables {
    config = {
      name  = "/app/db-password"
      value = "<YOUR_PARAMETER_VALUE>"
      type  = "Secret"
    }
  }

  expect_failures = [
    var.config,
  ]
}
