output "manifest" {
  description = "All outputs of the rds-instance component, collected on a single object."
  value = {
    instance_id            = module.instance.manifest.id
    instance_arn           = module.instance.manifest.arn
    endpoint               = module.instance.manifest.endpoint
    address                = module.instance.manifest.address
    port                   = module.instance.manifest.port
    security_group_id      = module.security_group.manifest.id
    master_user_secret_arn = module.instance.manifest.master_user_secret_arn
    kms_key_arn            = local.kms_key_arn
  }
}
