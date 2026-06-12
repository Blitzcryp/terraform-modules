# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider the analyzer arn is unknown, so we assert on
# known/derived values (name, type).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "account-external-access"
    }
  }

  assert {
    condition     = aws_accessanalyzer_analyzer.this.analyzer_name == "account-external-access"
    error_message = "Analyzer name must be passed through from config.name."
  }

  assert {
    condition     = aws_accessanalyzer_analyzer.this.type == "ACCOUNT"
    error_message = "Analyzer type must default to ACCOUNT (external-access detection)."
  }
}

# Negative case: an invalid analyzer type is rejected by config validation.
run "invalid_type_is_rejected" {
  command = plan

  variables {
    config = {
      name = "bad-type"
      type = "REGION"
    }
  }

  expect_failures = [
    var.config,
  ]
}
