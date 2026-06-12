output "manifest" {
  description = "All outputs of the step-function component, collected on a single object."
  value = {
    state_machine_arn  = module.state_machine.manifest.arn
    state_machine_name = module.state_machine.manifest.name
    role_arn           = module.exec_role.manifest.arn
    log_group_name     = module.log_group.manifest.name
    kms_key_arn        = local.effective_kms_arn
  }
}
