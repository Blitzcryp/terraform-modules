variable "config" {
  description = <<-EOT
    Configuration for the audit-logging component (PCI DSS Req 10 logging
    backbone). All inputs live on this single object. PCI-compliant defaults are
    baked into the optional() fields, so the caller only has to supply the
    required `name_prefix`. Insecure choices require flipping an explicit
    `allow_*` escape hatch that is passed down to the underlying atoms.
  EOT

  type = object({
    # name_prefix is REQUIRED: the base name for the log group, KMS alias and
    # flow-log role. The caller must decide it. No default.
    name_prefix = string

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---
    retention_in_days = optional(number, 365) # >= 1 year of audit logs
    kms_key_arn       = optional(string)      # BYOK: if set, no kms-key atom is created
    log_group_class   = optional(string, "STANDARD")

    create_flow_log_role        = optional(bool, true)
    flow_log_role_trust_service = optional(string, "vpc-flow-logs.amazonaws.com")

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_no_retention = optional(bool, false) # passed to the log-group atom
  })

  # no `default` here because name_prefix is required

  validation {
    condition     = length(var.config.name_prefix) > 0
    error_message = "config.name_prefix must be a non-empty string."
  }

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.config.log_group_class)
    error_message = "config.log_group_class must be STANDARD or INFREQUENT_ACCESS."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
