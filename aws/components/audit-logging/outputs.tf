output "manifest" {
  description = "All outputs of the audit-logging component, collected on a single object."
  value = {
    log_group_name = module.log_group.manifest.name
    log_group_arn  = module.log_group.manifest.arn

    # KMS: the effective key the log group is encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn
    # key_id / alias_arn are null when a BYO key is used (we did not create it).
    kms_key_id    = local.create_kms ? module.kms_key[0].manifest.key_id : null
    kms_alias_arn = local.create_kms ? module.kms_key[0].manifest.alias_arn : null

    # Flow-log delivery role ARN; null when create_flow_log_role = false.
    flow_log_role_arn = var.config.create_flow_log_role ? module.flow_log_role[0].manifest.arn : null
  }
}
