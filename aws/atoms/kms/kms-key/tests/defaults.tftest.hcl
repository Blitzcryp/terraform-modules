# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      description = "test key"
      alias       = "test/key"
    }
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == true
    error_message = "Key rotation must default to enabled (PCI DSS 3.6.4 / 3.7)."
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 30
    error_message = "Deletion window must default to 30 days."
  }

  assert {
    condition     = aws_kms_alias.this[0].name == "alias/test/key"
    error_message = "Alias must be prefixed with 'alias/'."
  }
}

run "rotation_disabled_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      enable_key_rotation = false
      # allow_rotation_disabled intentionally left at its false default
    }
  }

  expect_failures = [
    aws_kms_key.this,
  ]
}

run "deletion_window_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      deletion_window_in_days = 3
    }
  }

  expect_failures = [
    var.config,
  ]
}
