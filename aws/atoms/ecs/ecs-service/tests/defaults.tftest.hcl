# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name               = "test-svc"
      cluster_arn        = "arn:aws:ecs:eu-central-1:111122223333:cluster/test"
      task_definition    = "arn:aws:ecs:eu-central-1:111122223333:task-definition/test:1"
      subnet_ids         = ["subnet-aaaa", "subnet-bbbb"]
      security_group_ids = ["sg-cccc"]
    }
  }

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].assign_public_ip == false
    error_message = "Tasks must default to NO public IP (PCI DSS Req 1)."
  }

  assert {
    condition     = aws_ecs_service.this.enable_execute_command == false
    error_message = "ECS Exec must default to disabled (PCI DSS Req 7)."
  }

  assert {
    condition     = aws_ecs_service.this.deployment_circuit_breaker[0].enable == true && aws_ecs_service.this.deployment_circuit_breaker[0].rollback == true
    error_message = "Deployment circuit breaker + rollback must default to enabled."
  }
}

run "public_ip_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name               = "test-svc"
      cluster_arn        = "arn:aws:ecs:eu-central-1:111122223333:cluster/test"
      task_definition    = "arn:aws:ecs:eu-central-1:111122223333:task-definition/test:1"
      subnet_ids         = ["subnet-aaaa"]
      security_group_ids = ["sg-cccc"]
      assign_public_ip   = true
      # allow_public_ip intentionally left at its false default
    }
  }

  expect_failures = [
    aws_ecs_service.this,
  ]
}

run "execute_command_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name                   = "test-svc"
      cluster_arn            = "arn:aws:ecs:eu-central-1:111122223333:cluster/test"
      task_definition        = "arn:aws:ecs:eu-central-1:111122223333:task-definition/test:1"
      subnet_ids             = ["subnet-aaaa"]
      security_group_ids     = ["sg-cccc"]
      enable_execute_command = true
      # allow_execute_command intentionally left at its false default
    }
  }

  expect_failures = [
    aws_ecs_service.this,
  ]
}

run "deployment_controller_validation_rejects_invalid" {
  command = plan

  variables {
    config = {
      name                       = "test-svc"
      cluster_arn                = "arn:aws:ecs:eu-central-1:111122223333:cluster/test"
      task_definition            = "arn:aws:ecs:eu-central-1:111122223333:task-definition/test:1"
      subnet_ids                 = ["subnet-aaaa"]
      security_group_ids         = ["sg-cccc"]
      deployment_controller_type = "ROLLING"
    }
  }

  expect_failures = [
    var.config,
  ]
}
