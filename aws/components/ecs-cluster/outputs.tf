output "manifest" {
  description = "All outputs of the ecs-cluster component, collected on a single object."
  value = {
    cluster_id   = module.ecs_cluster.manifest.id
    cluster_arn  = module.ecs_cluster.manifest.arn
    cluster_name = module.ecs_cluster.manifest.name

    # The effective key the log group and ECS Exec are encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn

    log_group_name = module.log_group.manifest.name
  }
}
