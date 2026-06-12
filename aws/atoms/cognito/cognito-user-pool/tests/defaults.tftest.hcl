# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the user pool's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-pool"
    }
  }

  assert {
    condition     = aws_cognito_user_pool.this.mfa_configuration == "ON"
    error_message = "MFA must default to ON (PCI DSS Req 8.4 / 8.5)."
  }

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].minimum_length == 14
    error_message = "Password minimum length must default to 14 (PCI DSS Req 8.3.6)."
  }

  assert {
    condition     = aws_cognito_user_pool.this.password_policy[0].require_symbols == true
    error_message = "Password policy must require symbols by default (PCI DSS Req 8.3.6 complexity)."
  }

  assert {
    condition     = aws_cognito_user_pool.this.user_pool_add_ons[0].advanced_security_mode == "ENFORCED"
    error_message = "Advanced security mode must default to ENFORCED."
  }

  assert {
    condition     = aws_cognito_user_pool.this.software_token_mfa_configuration[0].enabled == true
    error_message = "Software (TOTP) token MFA must be enabled."
  }

  assert {
    condition     = aws_cognito_user_pool.this.deletion_protection == "ACTIVE"
    error_message = "Deletion protection must default to ACTIVE."
  }

  assert {
    condition     = length([for m in aws_cognito_user_pool.this.account_recovery_setting[0].recovery_mechanism : m if m.name == "verified_email"]) == 1
    error_message = "Account recovery must use verified_email only."
  }
}

run "mfa_off_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "test-pool"
      mfa_configuration = "OFF"
      # allow_mfa_off intentionally left at its false default
    }
  }

  expect_failures = [
    aws_cognito_user_pool.this,
  ]
}

run "mfa_off_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "test-pool"
      mfa_configuration = "OFF"
      allow_mfa_off     = true
    }
  }

  assert {
    condition     = aws_cognito_user_pool.this.mfa_configuration == "OFF"
    error_message = "Escape hatch must permit mfa_configuration=OFF."
  }
}

run "short_password_is_rejected" {
  command = plan

  variables {
    config = {
      name                    = "test-pool"
      password_minimum_length = 8
    }
  }

  expect_failures = [
    var.config,
  ]
}
