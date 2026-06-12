# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      name   = "test-postgres16"
      family = "postgres16"
    }
  }

  assert {
    condition     = aws_db_parameter_group.this.family == "postgres16"
    error_message = "family must be wired through to the parameter group."
  }

  assert {
    condition     = length(aws_db_parameter_group.this.parameter) == 0
    error_message = "parameters must default to an empty set."
  }
}

run "parameters_are_wired" {
  command = plan

  variables {
    config = {
      name   = "test-postgres16"
      family = "postgres16"
      parameters = [
        {
          name         = "rds.force_ssl"
          value        = "1"
          apply_method = "pending-reboot"
        },
      ]
    }
  }

  assert {
    condition     = length(aws_db_parameter_group.this.parameter) == 1
    error_message = "Supplied parameters must produce one parameter block each."
  }
}

run "invalid_apply_method_is_rejected" {
  command = plan

  variables {
    config = {
      name   = "test-postgres16"
      family = "postgres16"
      parameters = [
        {
          name         = "rds.force_ssl"
          value        = "1"
          apply_method = "whenever"
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
