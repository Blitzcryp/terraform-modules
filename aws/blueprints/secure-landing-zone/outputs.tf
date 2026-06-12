output "manifest" {
  description = "All outputs of the secure-landing-zone blueprint, collected on a single object. Each key is null when its capability is disabled."
  value = {
    # --- Account baseline (Req 8) ---
    password_policy_min_length = try(module.account_baseline[0].manifest.password_policy_min_length, null)

    # --- Audit logging backbone (Req 10) ---
    audit_log_group_name = try(module.audit_logging[0].manifest.log_group_name, null)

    # --- CloudTrail (Req 10) ---
    cloudtrail_arn         = try(module.cloudtrail[0].manifest.trail_arn, null)
    cloudtrail_bucket_name = try(module.cloudtrail[0].manifest.bucket_name, null)

    # --- CSPM posture stack (Req 6/10/11) ---
    security_hub_account_id = try(module.cspm[0].manifest.security_hub_account_id, null)
    guardduty_detector_id   = try(module.cspm[0].manifest.guardduty_detector_id, null)
    config_recorder_name    = try(module.cspm[0].manifest.config_recorder_name, null)
    inspector_id            = try(module.cspm[0].manifest.inspector_id, null)

    # --- Findings notification (Req 10) ---
    findings_topic_arn = try(module.findings_notification[0].manifest.topic_arn, null)

    # --- Baseline VPC (Req 1); null when the landing zone owns no network ---
    vpc_id = try(module.network[0].manifest.vpc_id, null)
  }
}
