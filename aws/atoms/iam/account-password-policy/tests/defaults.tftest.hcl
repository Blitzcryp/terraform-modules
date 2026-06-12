# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {}
  }

  assert {
    condition     = aws_iam_account_password_policy.this.minimum_password_length == 14
    error_message = "Minimum password length must default to 14 (PCI DSS Req 8.3.6: >= 12)."
  }

  assert {
    condition = (
      aws_iam_account_password_policy.this.require_lowercase_characters &&
      aws_iam_account_password_policy.this.require_uppercase_characters &&
      aws_iam_account_password_policy.this.require_numbers &&
      aws_iam_account_password_policy.this.require_symbols
    )
    error_message = "All character-complexity requirements must default to enabled (PCI DSS Req 8.3.6)."
  }

  assert {
    condition     = aws_iam_account_password_policy.this.password_reuse_prevention == 4
    error_message = "Password reuse prevention must default to 4 cycles (PCI DSS Req 8.3.7)."
  }

  assert {
    condition     = aws_iam_account_password_policy.this.max_password_age == 90
    error_message = "Max password age must default to 90 days (PCI DSS Req 8.3.9)."
  }
}

run "short_password_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      minimum_password_length = 8
      # allow_short_password intentionally left at its false default
    }
  }

  expect_failures = [
    aws_iam_account_password_policy.this,
  ]
}

run "short_password_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      minimum_password_length = 8
      allow_short_password    = true
    }
  }

  assert {
    condition     = aws_iam_account_password_policy.this.minimum_password_length == 8
    error_message = "The escape hatch must permit a sub-12 minimum_password_length."
  }
}

run "max_password_age_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      max_password_age = 400
    }
  }

  expect_failures = [
    var.config,
  ]
}
