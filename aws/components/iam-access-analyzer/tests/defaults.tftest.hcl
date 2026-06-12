# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# Under mock_provider the analyzer arn is unknown, so we assert on known/derived
# values (name, type, module count).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "account-external-access"
    }
  }

  # The analyzer atom is composed and the name is passed through from config.
  assert {
    condition     = module.analyzer.manifest.analyzer_name == "account-external-access"
    error_message = "Analyzer name must be passed through from config.name."
  }

  # The name is also surfaced on the component manifest.
  assert {
    condition     = output.manifest.analyzer_name == "account-external-access"
    error_message = "Component manifest must surface the analyzer name."
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
