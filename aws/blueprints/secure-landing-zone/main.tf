locals {
  module_tags = {
    Module = "blueprints/secure-landing-zone" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  name_prefix = var.config.name_prefix

  # --- Capability enable flags ----------------------------------------------
  account_baseline_enabled = var.config.enable_account_baseline
  audit_logging_enabled    = var.config.enable_audit_logging
  cloudtrail_enabled       = var.config.enable_cloudtrail
  cspm_enabled             = var.config.enable_cspm
  findings_enabled         = var.config.enable_findings_notification
  network_enabled          = var.config.enable_network

  # Shared BYO CMK (null = each component creates its own compliant CMK).
  shared_kms_key_arn = var.config.kms_key_arn
}

# --- 1. Account baseline (IAM password policy, PCI DSS Req 8) ----------------
module "account_baseline" {
  source = "../../components/account-baseline"
  count  = local.account_baseline_enabled ? 1 : 0

  config = {
    password_minimum_length   = var.config.password_policy.minimum_length
    password_max_age          = var.config.password_policy.max_age
    password_reuse_prevention = var.config.password_policy.reuse_prevention
    tags                      = local.tags
  }
}

# --- 2. Audit logging backbone (central KMS-encrypted log group + flow-log
#        role, PCI DSS Req 10). Accepts the shared BYO CMK when supplied. -----
module "audit_logging" {
  source = "../../components/audit-logging"
  count  = local.audit_logging_enabled ? 1 : 0

  config = {
    name_prefix = local.name_prefix
    kms_key_arn = local.shared_kms_key_arn
    tags        = local.tags
  }
}

# --- 3. CloudTrail (multi-region encrypted, log-file-validated trail, Req 10).
#        Accepts the shared BYO CMK when supplied. -----------------------------
module "cloudtrail" {
  source = "../../components/cloudtrail"
  count  = local.cloudtrail_enabled ? 1 : 0

  config = {
    name                  = local.name_prefix
    kms_key_arn           = local.shared_kms_key_arn
    is_organization_trail = var.config.cloudtrail_is_organization_trail
    tags                  = local.tags
  }
}

# --- 4. CSPM posture stack (Security Hub + AWS Config + GuardDuty + Inspector,
#        PCI DSS Req 6/10/11). Accepts the shared BYO CMK when supplied. -------
module "cspm" {
  source = "../../components/cspm"
  count  = local.cspm_enabled ? 1 : 0

  config = {
    name_prefix              = local.name_prefix
    kms_key_arn              = local.shared_kms_key_arn
    inspector_resource_types = var.config.cspm_inspector_resource_types
    tags                     = local.tags
  }
}

# --- 5. Findings notification (Security Hub / Inspector / GuardDuty findings ->
#        encrypted SNS via EventBridge, PCI DSS Req 10). Routes by event pattern,
#        NOT by resource ARN — independent of the cspm component. Accepts the
#        shared BYO CMK when supplied. ------------------------------------------
module "findings_notification" {
  source = "../../components/findings-notification"
  count  = local.findings_enabled ? 1 : 0

  config = {
    name        = local.name_prefix
    source      = var.config.findings_source
    kms_key_arn = local.shared_kms_key_arn
    tags        = local.tags
  }
}

# --- 6. Baseline VPC (secure-network, PCI DSS Req 1). OFF by default; a landing
#        zone may or may not own networking. Flow logs are on by default in the
#        component. -------------------------------------------------------------
module "network" {
  source = "../../components/secure-network"
  count  = local.network_enabled ? 1 : 0

  config = {
    name       = local.name_prefix
    cidr_block = var.config.vpc_cidr
    subnets    = var.config.subnets
    tags       = local.tags
  }
}
