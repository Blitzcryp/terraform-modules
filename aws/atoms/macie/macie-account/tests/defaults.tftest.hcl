# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider the id/service_role are unknown, so we assert on
# known/derived values (status, finding cadence).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {}
  }

  assert {
    condition     = aws_macie2_account.this.status == "ENABLED"
    error_message = "Macie must be ENABLED by default for continuous S3 sensitive-data discovery."
  }

  assert {
    condition     = aws_macie2_account.this.finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "Finding publishing frequency must default to FIFTEEN_MINUTES."
  }
}

# Negative case: an invalid finding_publishing_frequency is rejected.
run "invalid_frequency_is_rejected" {
  command = plan

  variables {
    config = {
      finding_publishing_frequency = "DAILY"
    }
  }

  expect_failures = [
    var.config,
  ]
}
