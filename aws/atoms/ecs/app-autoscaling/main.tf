locals {
  module_tags = {
    Module = "atoms/ecs/app-autoscaling" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# Registers the ECS service's DesiredCount as a scalable target. This atom does
# not create the service — resource_id flows in by reference.
resource "aws_appautoscaling_target" "this" {
  resource_id        = var.config.resource_id
  min_capacity       = var.config.min_capacity
  max_capacity       = var.config.max_capacity
  scalable_dimension = var.config.scalable_dimension
  service_namespace  = var.config.service_namespace

  tags = local.tags
}

# CPU target-tracking policy: ECS adds/removes tasks to hold average CPU at the
# configured target percentage.
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${aws_appautoscaling_target.this.resource_id}-cpu-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.config.target_cpu
    scale_in_cooldown  = var.config.scale_in_cooldown
    scale_out_cooldown = var.config.scale_out_cooldown
  }
}

# Memory target-tracking policy: holds average memory utilisation at target.
resource "aws_appautoscaling_policy" "memory" {
  name               = "${aws_appautoscaling_target.this.resource_id}-mem-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.config.target_memory
    scale_in_cooldown  = var.config.scale_in_cooldown
    scale_out_cooldown = var.config.scale_out_cooldown
  }
}
