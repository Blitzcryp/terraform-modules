variable "config" {
  description = <<-EOT
    Configuration for the S3 bucket. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so passing
    only the required `bucket` yields a compliant bucket. Insecure choices
    require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    bucket = string # required — globally unique, DNS-compliant
    tags   = optional(map(string), {})

    # --- Encryption (PCI DSS Req 3: protect stored cardholder data) ---
    enable_encryption = optional(bool, true)
    kms_key_arn       = optional(string) # null = AWS-managed aws:kms key

    # --- Versioning (PCI DSS Req 10: protect against tampering/loss) ---
    enable_versioning = optional(bool, true)

    # --- Public access (PCI DSS Req 1/7: restrict exposure) ---
    block_public_access = optional(bool, true)
    object_ownership    = optional(string, "BucketOwnerEnforced")

    # --- Bucket policy ---
    additional_policy_statements = optional(any, [])

    # --- Access logging (PCI DSS Req 10: audit trails) ---
    logging_target_bucket = optional(string) # null = no access logging
    logging_target_prefix = optional(string, "s3-access-logs/")

    # --- Lifecycle ---
    lifecycle_rules = optional(list(object({
      id                                     = string
      status                                 = optional(string, "Enabled")
      prefix                                 = optional(string)
      expiration_days                        = optional(number)
      noncurrent_version_expiration_days     = optional(number)
      abort_incomplete_multipart_upload_days = optional(number)
    })), [])

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted   = optional(bool, false)
    allow_unversioned   = optional(bool, false)
    allow_public_access = optional(bool, false)
  })

  # no `default` here because `bucket` is required

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.config.bucket))
    error_message = "config.bucket must be 3-63 chars, lowercase letters, numbers, hyphens or dots, and start/end alphanumeric."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn must be a valid KMS key ARN (arn:aws:kms:...) or null."
  }

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.config.object_ownership)
    error_message = "config.object_ownership must be BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  }
}
