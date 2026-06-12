# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      family                = "test-app"
      container_definitions = "[{\"name\":\"app\",\"image\":\"nginx\",\"essential\":true}]"
    }
  }

  assert {
    condition     = aws_ecs_task_definition.this.network_mode == "awsvpc"
    error_message = "network_mode must default to awsvpc (task-level ENI isolation)."
  }

  assert {
    condition     = aws_ecs_task_definition.this.requires_compatibilities == toset(["FARGATE"])
    error_message = "requires_compatibilities must default to FARGATE (managed, patched runtime)."
  }
}

run "container_definitions_must_be_valid_json" {
  command = plan

  variables {
    config = {
      family                = "test-app"
      container_definitions = "this-is-not-json"
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "network_mode_validation_rejects_invalid" {
  command = plan

  variables {
    config = {
      family                = "test-app"
      container_definitions = "[]"
      network_mode          = "magic"
    }
  }

  expect_failures = [
    var.config,
  ]
}
