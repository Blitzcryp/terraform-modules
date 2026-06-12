# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name        = "/test/app/audit"
      kms_key_arn = "arn:aws:kms:eu-central-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    }
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 365
    error_message = "retention_in_days must default to 365 (PCI DSS Req 10.5/10.7, >= 1 year)."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id != null
    error_message = "Log group must be KMS-encrypted at rest (PCI DSS Req 3)."
  }
}

run "retention_validation_rejects_invalid_value" {
  command = plan

  variables {
    config = {
      name              = "/test/app/audit"
      kms_key_arn       = "arn:aws:kms:eu-central-1:123456789012:key/00000000-0000-0000-0000-000000000000"
      retention_in_days = 999
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name        = "/test/app/audit"
      kms_key_arn = null
      # allow_unencrypted intentionally left false
    }
  }

  expect_failures = [
    aws_cloudwatch_log_group.this,
  ]
}

run "no_retention_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "/test/app/audit"
      kms_key_arn       = "arn:aws:kms:eu-central-1:123456789012:key/00000000-0000-0000-0000-000000000000"
      retention_in_days = 0
      # allow_no_retention intentionally left false
    }
  }

  expect_failures = [
    aws_cloudwatch_log_group.this,
  ]
}
