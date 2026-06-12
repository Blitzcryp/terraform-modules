output "manifest" {
  description = "All outputs of the ECS app-autoscaling atom, collected on a single object."
  value = {
    target_resource_id = aws_appautoscaling_target.this.resource_id
    policy_arns = {
      cpu    = aws_appautoscaling_policy.cpu.arn
      memory = aws_appautoscaling_policy.memory.arn
    }
  }
}
