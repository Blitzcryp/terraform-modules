variable "config" {
  description = <<-EOT
    Configuration for the private-encrypted-bucket component. All inputs live on
    this single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so passing only the required `bucket` yields a fully locked-down,
    SSE-KMS-encrypted, versioned, access-logged, public-access-blocked bucket.

    This component composes atoms via module blocks: a kms-key atom (unless a
    `kms_key_arn` is supplied), the main s3-bucket atom, and — when access
    logging is enabled and no external `access_log_bucket` is given — a companion
    s3-bucket atom that receives the server access logs.
  EOT

  type = object({
    # --- Required: the caller must decide the main bucket name. ---
    bucket = string # globally unique, DNS-compliant

    # --- Encryption (PCI DSS Req 3) ---
    # BYOK: when set, the supplied CMK is used and no kms-key atom is created.
    # When null, a dedicated kms-key atom is created for this bucket.
    kms_key_arn = optional(string)

    # --- Versioning (PCI DSS Req 10) ---
    enable_versioning = optional(bool, true)

    # --- Access logging (PCI DSS Req 10: audit trails) ---
    enable_access_logging = optional(bool, true)
    # External log target name. When null AND logging enabled, a companion log
    # bucket named "${bucket}-logs" is created.
    access_log_bucket = optional(string)
    access_log_prefix = optional(string, "s3-access-logs/")

    # --- Lifecycle (shape matches the s3-bucket atom's lifecycle_rules) ---
    lifecycle_rules = optional(list(any), [])

    # --- Bucket policy ---
    additional_policy_statements = optional(any, [])

    # --- Tagging ---
    tags = optional(map(string), {})
  })

  # no `default` here because `bucket` is required

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.config.bucket))
    error_message = "config.bucket must be 3-63 chars, lowercase letters, numbers, hyphens or dots, and start/end alphanumeric."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = var.config.access_log_bucket == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.config.access_log_bucket))
    error_message = "config.access_log_bucket, when set, must be a valid S3 bucket name (3-63 chars, lowercase, start/end alphanumeric)."
  }
}
