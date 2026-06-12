output "manifest" {
  description = "All outputs of the backup component, collected on a single object."
  value = {
    vault_arn  = module.vault.manifest.arn
    vault_name = module.vault.manifest.name

    plan_id  = module.plan.manifest.id
    plan_arn = module.plan.manifest.arn

    selection_id = module.selection.manifest.id

    backup_role_arn = module.backup_role.manifest.arn

    # The effective key recovery points are encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn
  }
}
