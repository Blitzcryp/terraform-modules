# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider, computed values such as the trail ARN are unknown,
# so we assert on known/derived inputs and on plan success rather than ARNs.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name           = "test-trail"
      s3_bucket_name = "test-cloudtrail-logs"
      kms_key_arn    = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = aws_cloudtrail.this.is_multi_region_trail == true
    error_message = "Trail must default to multi-region (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_cloudtrail.this.enable_log_file_validation == true
    error_message = "Log file validation must default to enabled (PCI DSS Req 10.5)."
  }

  assert {
    condition     = aws_cloudtrail.this.include_global_service_events == true
    error_message = "Global service events must default to enabled."
  }

  assert {
    condition     = aws_cloudtrail.this.enable_logging == true
    error_message = "Logging must default to enabled."
  }

  assert {
    condition     = aws_cloudtrail.this.is_organization_trail == false
    error_message = "Organization trail must default to false."
  }

  assert {
    condition     = aws_cloudtrail.this.kms_key_id == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "kms_key_id must be wired from config.kms_key_arn."
  }
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name           = "test-trail"
      s3_bucket_name = "test-cloudtrail-logs"
      # kms_key_arn omitted (null) and allow_unencrypted left at its false default
    }
  }

  expect_failures = [
    aws_cloudtrail.this,
  ]
}

run "unencrypted_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "test-trail"
      s3_bucket_name    = "test-cloudtrail-logs"
      allow_unencrypted = true
    }
  }

  assert {
    condition     = aws_cloudtrail.this.kms_key_id == null
    error_message = "With the escape hatch set, an unencrypted trail (no kms_key_id) must be permitted."
  }
}

run "mismatched_cwl_pair_is_rejected" {
  command = plan

  variables {
    config = {
      name                       = "test-trail"
      s3_bucket_name             = "test-cloudtrail-logs"
      kms_key_arn                = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      cloud_watch_logs_group_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/cloudtrail/test:*"
      # cloud_watch_logs_role_arn intentionally omitted -> validation must fail
    }
  }

  expect_failures = [
    var.config,
  ]
}
