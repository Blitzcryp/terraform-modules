# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.

mock_provider "aws" {}

run "secure_defaults_compose_password_policy" {
  command = plan

  variables {
    config = {}
  }

  assert {
    condition     = module.password_policy.manifest.minimum_password_length == 14
    error_message = "Account baseline must set a 14-char minimum password length (PCI DSS Req 8.3.6)."
  }

  assert {
    condition     = module.password_policy.manifest.max_password_age == 90
    error_message = "Account baseline must set a 90-day max password age (PCI DSS Req 8.3.9)."
  }

  assert {
    condition     = module.password_policy.manifest.password_reuse_prevention == 4
    error_message = "Account baseline must prevent reuse of the last 4 passwords (PCI DSS Req 8.3.7)."
  }
}

run "short_password_is_rejected" {
  command = plan

  variables {
    config = {
      password_minimum_length = 8
    }
  }

  # The component does not surface an escape hatch, so a sub-12 minimum is
  # rejected by the component's own config validation (PCI DSS Req 8.3.6).
  expect_failures = [
    var.config,
  ]
}

run "invalid_max_age_is_rejected" {
  command = plan

  variables {
    config = {
      password_max_age = 400
    }
  }

  expect_failures = [
    var.config,
  ]
}
