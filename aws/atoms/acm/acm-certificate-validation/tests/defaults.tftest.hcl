# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. certificate_arn echoes a known input, so it can be
# asserted directly.

mock_provider "aws" {}

run "passes_through_certificate_arn" {
  command = plan

  variables {
    config = {
      certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/00000000-0000-0000-0000-000000000000"
      validation_record_fqdns = [
        "_a79865eb4cd1a6ab990a45779b4e0b96.app.example.com",
      ]
    }
  }

  assert {
    condition     = aws_acm_certificate_validation.this.certificate_arn == "arn:aws:acm:eu-central-1:111122223333:certificate/00000000-0000-0000-0000-000000000000"
    error_message = "certificate_arn must be planned with the supplied value."
  }
}

# --- Negative case: a non-ACM ARN is rejected by config validation. ---
run "invalid_certificate_arn_is_rejected" {
  command = plan

  variables {
    config = {
      certificate_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  expect_failures = [
    var.config,
  ]
}
