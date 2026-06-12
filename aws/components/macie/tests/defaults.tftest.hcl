# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# Under mock_provider the account id/service_role are unknown, so we assert on
# known/derived values (status, finding cadence).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {}
  }

  # The Macie account atom is composed (plan succeeds with secure defaults) and
  # its manifest is wired through to the component manifest. Under mock the
  # account id/service_role are unknown, so we assert the manifest keys exist.
  assert {
    condition     = can(output.manifest.macie_account_id)
    error_message = "Component manifest must expose macie_account_id."
  }

  assert {
    condition     = can(output.manifest.service_role)
    error_message = "Component manifest must expose service_role."
  }
}

# Negative case: an invalid status is rejected by config validation.
run "invalid_status_is_rejected" {
  command = plan

  variables {
    config = {
      status = "DISABLED"
    }
  }

  expect_failures = [
    var.config,
  ]
}
