# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the OAC atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-s3-oac"
    }
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this.signing_behavior == "always"
    error_message = "Signing behavior must default to 'always' so the origin is always signed."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this.signing_protocol == "sigv4"
    error_message = "Signing protocol must default to sigv4."
  }

  assert {
    condition     = aws_cloudfront_origin_access_control.this.origin_access_control_origin_type == "s3"
    error_message = "Origin type must default to s3."
  }
}

run "invalid_signing_behavior_is_rejected" {
  command = plan

  variables {
    config = {
      name             = "test-bad-oac"
      signing_behavior = "sometimes"
    }
  }

  expect_failures = [
    var.config,
  ]
}
