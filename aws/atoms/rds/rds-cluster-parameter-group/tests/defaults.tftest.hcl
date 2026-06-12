# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      name   = "test-aurora-postgresql16"
      family = "aurora-postgresql16"
    }
  }

  assert {
    condition     = aws_rds_cluster_parameter_group.this.family == "aurora-postgresql16"
    error_message = "family must be wired through to the cluster parameter group."
  }

  assert {
    condition     = length(aws_rds_cluster_parameter_group.this.parameter) == 0
    error_message = "parameters must default to an empty set."
  }
}

run "parameters_are_wired" {
  command = plan

  variables {
    config = {
      name   = "test-aurora-postgresql16"
      family = "aurora-postgresql16"
      parameters = [
        {
          name  = "rds.force_ssl"
          value = "1"
        },
      ]
    }
  }

  assert {
    condition     = length(aws_rds_cluster_parameter_group.this.parameter) == 1
    error_message = "Supplied parameters must produce one parameter block each."
  }
}

run "invalid_apply_method_is_rejected" {
  command = plan

  variables {
    config = {
      name   = "test-aurora-postgresql16"
      family = "aurora-postgresql16"
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
