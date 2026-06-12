output "manifest" {
  description = "All outputs of the rds-aurora-serverless component, collected on a single object."
  value = {
    cluster_id             = module.cluster.manifest.cluster_id
    cluster_arn            = module.cluster.manifest.cluster_arn
    endpoint               = module.cluster.manifest.endpoint
    reader_endpoint        = module.cluster.manifest.reader_endpoint
    port                   = module.cluster.manifest.port
    security_group_id      = module.security_group.manifest.id
    master_user_secret_arn = module.cluster.manifest.master_user_secret_arn
    kms_key_arn            = local.kms_key_arn
  }
}
