output "manifest" {
  description = "All outputs of the ec2-instance component, collected on a single object."
  value = {
    instance_id          = module.instance.manifest.id
    instance_arn         = module.instance.manifest.arn
    private_ip           = module.instance.manifest.private_ip
    security_group_id    = module.security_group.manifest.id
    role_arn             = module.role.manifest.arn
    instance_profile_arn = module.instance_profile.manifest.arn
    kms_key_arn          = local.kms_key_arn
  }
}
