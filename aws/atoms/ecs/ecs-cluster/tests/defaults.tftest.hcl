# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name                           = "test-cluster"
      kms_key_arn                    = "arn:aws:kms:eu-central-1:111122223333:key/abc"
      execute_command_log_group_name = "/ecs/test/exec"
    }
  }

  assert {
    condition     = one([for s in aws_ecs_cluster.this.setting : s.value if s.name == "containerInsights"]) == "enabled"
    error_message = "Container Insights must default to enabled (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_ecs_cluster.this.configuration[0].execute_command_configuration[0].log_configuration[0].cloud_watch_encryption_enabled == true
    error_message = "ECS Exec CloudWatch logs must be encrypted when a KMS key + log group are provided (PCI DSS Req 3/10)."
  }

  assert {
    condition     = aws_ecs_cluster_capacity_providers.this.capacity_providers == toset(["FARGATE", "FARGATE_SPOT"])
    error_message = "Capacity providers must default to Fargate-only."
  }
}

run "container_insights_disabled_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name                      = "test-cluster"
      enable_container_insights = false
      # allow_container_insights_disabled intentionally left at its false default
    }
  }

  expect_failures = [
    aws_ecs_cluster.this,
  ]
}

run "name_validation_rejects_invalid" {
  command = plan

  variables {
    config = {
      name = "bad name with spaces!"
    }
  }

  expect_failures = [
    var.config,
  ]
}
