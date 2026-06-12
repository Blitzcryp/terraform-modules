output "manifest" {
  description = "All outputs of the CSPM baseline component, collected on a single object."
  value = {
    # Security Hub: account id; null when disabled.
    security_hub_account_id = var.config.enable_security_hub ? module.security_hub[0].manifest.account_id : null

    # AWS Config: recorder name and the delivery bucket ARN; null when disabled.
    config_recorder_name = var.config.enable_config ? module.config_recorder[0].manifest.recorder_name : null
    config_bucket_arn    = var.config.enable_config ? module.config_bucket[0].manifest.arn : null
    config_role_arn      = var.config.enable_config ? module.config_role[0].manifest.arn : null

    # GuardDuty: detector id; null when disabled.
    guardduty_detector_id = var.config.enable_guardduty ? module.guardduty[0].manifest.detector_id : null

    # Inspector v2: enabler id; null when disabled.
    inspector_id = var.config.enable_inspector ? module.inspector[0].manifest.id : null

    # The effective CMK encrypting the Config delivery bucket / posture services
    # (created by this component, or the BYO key when supplied).
    kms_key_arn = local.effective_kms_arn
  }
}
