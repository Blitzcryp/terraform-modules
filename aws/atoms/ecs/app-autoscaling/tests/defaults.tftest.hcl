# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under the mock, computed ARNs are unknown, so we assert
# on known/derived values (capacity bounds, metric types, derived names) and on
# plan success / validation behaviour rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      resource_id = "service/test-cluster/test-service"
    }
  }

  assert {
    condition     = aws_appautoscaling_target.this.min_capacity == 2
    error_message = "min_capacity must default to 2 for availability."
  }

  assert {
    condition     = aws_appautoscaling_target.this.max_capacity == 10
    error_message = "max_capacity must default to 10."
  }

  assert {
    condition     = aws_appautoscaling_target.this.scalable_dimension == "ecs:service:DesiredCount"
    error_message = "scalable_dimension must default to ecs:service:DesiredCount."
  }

  assert {
    condition     = aws_appautoscaling_policy.cpu.target_tracking_scaling_policy_configuration[0].predefined_metric_specification[0].predefined_metric_type == "ECSServiceAverageCPUUtilization"
    error_message = "CPU policy must use the ECSServiceAverageCPUUtilization predefined metric."
  }

  assert {
    condition     = aws_appautoscaling_policy.memory.target_tracking_scaling_policy_configuration[0].predefined_metric_specification[0].predefined_metric_type == "ECSServiceAverageMemoryUtilization"
    error_message = "Memory policy must use the ECSServiceAverageMemoryUtilization predefined metric."
  }

  assert {
    condition     = aws_appautoscaling_policy.cpu.target_tracking_scaling_policy_configuration[0].target_value == 60
    error_message = "CPU target_value must default to 60."
  }

  assert {
    condition     = aws_appautoscaling_policy.memory.target_tracking_scaling_policy_configuration[0].target_value == 70
    error_message = "Memory target_value must default to 70."
  }

  # manifest exposes the derived target resource id (known at plan time).
  assert {
    condition     = output.manifest.target_resource_id == "service/test-cluster/test-service"
    error_message = "manifest.target_resource_id must echo the configured resource_id."
  }
}

# Negative case: a malformed resource_id is rejected by the config validation.
run "invalid_resource_id_is_rejected" {
  command = plan

  variables {
    config = {
      resource_id = "not-a-service-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative case: max_capacity below min_capacity is rejected by validation.
run "max_below_min_is_rejected" {
  command = plan

  variables {
    config = {
      resource_id  = "service/test-cluster/test-service"
      min_capacity = 5
      max_capacity = 2
    }
  }

  expect_failures = [
    var.config,
  ]
}
