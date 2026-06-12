output "manifest" {
  description = "All outputs of the efs component, collected on a single object."
  value = {
    file_system_id   = module.file_system.manifest.id
    file_system_arn  = module.file_system.manifest.arn
    dns_name         = module.file_system.manifest.dns_name
    mount_target_ids = { for k, m in module.mount_target : k => m.manifest.id }
    security_group_id = module.security_group.manifest.id
    kms_key_arn      = local.kms_key_arn
    access_point_ids = { for k, a in module.access_point : k => a.manifest.id }
  }
}
