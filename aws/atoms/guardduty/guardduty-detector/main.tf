locals {
  module_tags = {
    Module = "atoms/guardduty/guardduty-detector" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Map of GuardDuty protection features -> ENABLED/DISABLED status, derived from
  # the boolean config toggles. Features are managed as separate, tightly-coupled
  # aws_guardduty_detector_feature resources (the `datasources` block is
  # deprecated since the 2023 GuardDuty console redesign).
  features = {
    S3_DATA_EVENTS         = var.config.enable_s3_protection ? "ENABLED" : "DISABLED"
    EKS_AUDIT_LOGS         = var.config.enable_kubernetes_protection ? "ENABLED" : "DISABLED"
    EBS_MALWARE_PROTECTION = var.config.enable_malware_protection ? "ENABLED" : "DISABLED"
  }
}

# Enables Amazon GuardDuty threat detection in the current account/region
# (PCI DSS Req 10/11 continuous monitoring).
resource "aws_guardduty_detector" "this" {
  # checkov:skip=CKV_AWS_238: enable defaults to true via config.enable
  # (optional(bool, true)); checkov cannot statically resolve the value through
  # the config object, but the secure default is enforced by the secure_defaults
  # test (PCI DSS Req 10/11 continuous monitoring).
  enable                       = var.config.enable
  finding_publishing_frequency = var.config.finding_publishing_frequency

  tags = local.tags
}

# Tightly-coupled protection features: meaningless without the detector above.
resource "aws_guardduty_detector_feature" "this" {
  for_each = local.features

  detector_id = aws_guardduty_detector.this.id
  name        = each.key
  status      = each.value
}
