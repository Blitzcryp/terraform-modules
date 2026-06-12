output "manifest" {
  description = "All outputs of the autoscaling-group component, collected on a single object."
  value = {
    asg_arn            = module.autoscaling_group.manifest.arn
    asg_name           = module.autoscaling_group.manifest.name
    launch_template_id = module.launch_template.manifest.id
    security_group_id  = module.security_group.manifest.id
    role_arn           = module.role.manifest.arn
    kms_key_arn        = local.kms_key_arn
  }
}
