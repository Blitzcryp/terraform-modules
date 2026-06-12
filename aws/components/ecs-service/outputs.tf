output "manifest" {
  description = "All outputs of the ecs-service component, collected on a single object."
  value = {
    service_id          = module.ecs_service.manifest.id
    service_name        = module.ecs_service.manifest.name
    security_group_id   = module.security_group.manifest.id
    task_definition_arn = module.task_definition.manifest.arn
    log_group_name      = module.log_group.manifest.name

    # Autoscaling policy ARNs; null when autoscaling is disabled.
    autoscaling_policy_arns = var.config.enable_autoscaling ? module.autoscaling[0].manifest.policy_arns : null
  }
}
