# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the module's defaults and tag conversion.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      name                = "test-app"
      launch_template_id  = "lt-0a1b2c3d4e5f60718"
      vpc_zone_identifier = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
    }
  }

  # Sizing defaults: 2 / 4 / 2.
  assert {
    condition     = aws_autoscaling_group.this.min_size == 2 && aws_autoscaling_group.this.max_size == 4 && aws_autoscaling_group.this.desired_capacity == 2
    error_message = "ASG must default to min=2, max=4, desired=2."
  }

  # Health check defaults.
  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "EC2" && aws_autoscaling_group.this.health_check_grace_period == 300
    error_message = "ASG must default to EC2 health checks with a 300s grace period."
  }

  # Launch template wired with $Latest version.
  assert {
    condition     = aws_autoscaling_group.this.launch_template[0].id == "lt-0a1b2c3d4e5f60718" && aws_autoscaling_group.this.launch_template[0].version == "$Latest"
    error_message = "ASG must reference the supplied launch template at $Latest."
  }

  # The module-identity tag is converted into a propagating tag {} block.
  assert {
    condition     = length([for t in aws_autoscaling_group.this.tag : t if t.key == "Module" && t.value == "atoms/ec2/autoscaling-group" && t.propagate_at_launch]) == 1
    error_message = "Merged tags must become propagating tag {} blocks (including the Module identity tag)."
  }
}

run "merges_caller_tags" {
  command = plan

  variables {
    config = {
      name                = "test-app"
      launch_template_id  = "lt-0a1b2c3d4e5f60718"
      vpc_zone_identifier = ["subnet-0a1b2c3d4e5f60001"]
      tags = {
        Environment = "test"
      }
    }
  }

  # Module identity tag + the one caller tag => 2 tag {} blocks, all propagating.
  assert {
    condition     = length(aws_autoscaling_group.this.tag) == 2
    error_message = "Caller tags must be merged with the module identity tag into tag {} blocks."
  }

  assert {
    condition     = alltrue([for t in aws_autoscaling_group.this.tag : t.propagate_at_launch])
    error_message = "Every ASG tag must propagate at launch."
  }
}

# Negative: desired_capacity above max_size fails the config validation.
run "desired_above_max_rejected" {
  command = plan

  variables {
    config = {
      name                = "test-app"
      launch_template_id  = "lt-0a1b2c3d4e5f60718"
      vpc_zone_identifier = ["subnet-0a1b2c3d4e5f60001"]
      min_size            = 2
      max_size            = 4
      desired_capacity    = 5
    }
  }

  expect_failures = [
    var.config,
  ]
}
