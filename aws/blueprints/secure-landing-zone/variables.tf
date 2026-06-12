variable "config" {
  description = <<-EOT
    Single configuration object for the secure-landing-zone BLUEPRINT: an
    account-wide security baseline for a PCI-DSS environment, composed entirely
    from components (no atoms, no raw resources). All inputs live on this one
    object.

    Secure-by-default: with only a `name_prefix` the blueprint turns on the full
    detective/preventive baseline — an IAM password policy (Req 8), a central
    KMS-encrypted audit log group + flow-log role (Req 10), a multi-region
    encrypted+validated CloudTrail (Req 10), the CSPM posture stack of Security
    Hub + AWS Config + GuardDuty + Inspector (Req 6/10/11), and a findings
    notification pipeline routing those findings to an encrypted SNS topic (Req
    10). Each capability is individually gated by an `enable_*` flag.

    A baseline VPC (secure-network, Req 1) is OFF by default because a landing
    zone may or may not own networking; enable it with `enable_network` and a
    `subnets` list.

    A single bring-your-own CMK (`kms_key_arn`) can be threaded into every
    component that accepts one (audit-logging, cloudtrail, cspm,
    findings-notification); otherwise each component creates its own compliant
    CMK.
  EOT

  type = object({
    # --- Always required ---
    name_prefix = string                    # base name fanned into every composed component
    tags        = optional(map(string), {}) # instance tags (global tags come from provider default_tags)

    # --- Shared BYO CMK (optional) ---
    # When set, this CMK encrypts the audit log group, the CloudTrail store, the
    # AWS Config delivery bucket and the findings SNS topic. When null, each of
    # those components owns and creates its own compliant CMK.
    kms_key_arn = optional(string)

    # --- Capability: account baseline (IAM password policy, PCI DSS Req 8) ---
    enable_account_baseline = optional(bool, true)
    password_policy = optional(object({
      minimum_length   = optional(number, 14) # PCI 8.3.6: >= 12
      max_age          = optional(number, 90) # PCI 8.3.9: rotate <= 90 days
      reuse_prevention = optional(number, 4)  # PCI 8.3.7: >= 4 cycles
    }), {})

    # --- Capability: audit logging backbone (central log group + CMK, Req 10) ---
    enable_audit_logging = optional(bool, true)

    # --- Capability: CloudTrail (multi-region encrypted validated trail, Req 10) ---
    enable_cloudtrail                = optional(bool, true)
    cloudtrail_is_organization_trail = optional(bool, false)

    # --- Capability: CSPM posture stack (Security Hub + Config + GuardDuty + Inspector) ---
    enable_cspm                   = optional(bool, true)
    cspm_inspector_resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])

    # --- Capability: findings notification (findings -> encrypted SNS, Req 10) ---
    enable_findings_notification = optional(bool, true)
    findings_source              = optional(string, "all")

    # --- Capability: baseline VPC (secure-network, PCI DSS Req 1). OFF by default. ---
    enable_network = optional(bool, false)
    vpc_cidr       = optional(string, "10.0.0.0/16")
    # Subnets are PRIVATE by default (public=false); a public subnet is an
    # intentional, auditable choice. Required (non-empty) only when enable_network.
    subnets = optional(list(object({
      name              = string
      cidr_block        = string
      availability_zone = string
      public            = optional(bool, false)
    })), [])
  })

  # no `default` here because name_prefix is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,200}$", var.config.name_prefix))
    error_message = "config.name_prefix must be 1-200 chars of letters, numbers, or hyphens."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = var.config.password_policy.minimum_length >= 12
    error_message = "config.password_policy.minimum_length must be >= 12 (PCI DSS Req 8.3.6)."
  }

  validation {
    condition     = var.config.password_policy.max_age >= 1 && var.config.password_policy.max_age <= 365
    error_message = "config.password_policy.max_age must be between 1 and 365 days (PCI DSS Req 8.3.9)."
  }

  validation {
    condition     = var.config.password_policy.reuse_prevention >= 4
    error_message = "config.password_policy.reuse_prevention must be >= 4 (PCI DSS Req 8.3.7)."
  }

  validation {
    condition     = contains(["securityhub", "inspector", "guardduty", "all"], var.config.findings_source)
    error_message = "config.findings_source must be one of securityhub, inspector, guardduty, all."
  }

  validation {
    condition = length(var.config.cspm_inspector_resource_types) > 0 && alltrue([
      for t in var.config.cspm_inspector_resource_types :
      contains(["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"], t)
    ])
    error_message = "config.cspm_inspector_resource_types must be a non-empty subset of EC2, ECR, LAMBDA, LAMBDA_CODE."
  }

  validation {
    condition     = !var.config.enable_network || can(cidrhost(var.config.vpc_cidr, 0))
    error_message = "config.vpc_cidr must be a valid IPv4 CIDR (e.g. 10.0.0.0/16) when config.enable_network = true."
  }

  # A landing zone that owns networking must define at least one subnet.
  validation {
    condition     = !var.config.enable_network || length(var.config.subnets) > 0
    error_message = "When config.enable_network = true you must define at least one entry in config.subnets."
  }
}
