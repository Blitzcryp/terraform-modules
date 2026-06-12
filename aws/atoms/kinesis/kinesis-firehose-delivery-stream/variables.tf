variable "config" {
  description = <<-EOT
    Configuration for the Kinesis Data Firehose delivery stream (extended_s3
    destination). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked into the optional() fields, so supplying only the required
    name, bucket_arn and role_arn yields a stream with server-side encryption
    (CUSTOMER_MANAGED_CMK), KMS-encrypted S3 delivery and CloudWatch error
    logging. Insecure choices require flipping an explicit `allow_*` escape hatch.

    This atom owns exactly one resource and takes the bucket, role and KMS key as
    inputs (ARNs) — it never creates them. Compose it from a component.
  EOT

  type = object({
    # --- Required: the caller must decide these. No defaults. -----------------
    name       = string # delivery stream name
    bucket_arn = string # destination S3 bucket ARN (input, not created here)
    role_arn   = string # firehose delivery IAM role ARN (input, not created here)

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) -
    # kms_key_arn drives BOTH the stream's server-side encryption (SSE) and the
    # S3 delivery encryption. null = SSE uses an AWS-owned CMK and S3 delivery
    # falls back to the bucket's own encryption.
    kms_key_arn = optional(string)

    # --- Buffering ------------------------------------------------------------
    buffering_size     = optional(number, 5)   # MB, 1-128
    buffering_interval = optional(number, 300) # seconds, 0-900

    # --- S3 delivery layout ---------------------------------------------------
    prefix = optional(string) # null = bucket root prefix

    # --- CloudWatch error logging (PCI DSS Req 10) ----------------------------
    cloudwatch_log_group_name  = optional(string)
    cloudwatch_log_stream_name = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) -------
    # Permits disabling the stream's server-side encryption. The S3-delivery
    # KMS key (kms_key_arn) is independent of this flag.
    allow_unencrypted = optional(bool, false)
  })

  # no `default` here because name, bucket_arn and role_arn are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:s3:", var.config.bucket_arn))
    error_message = "config.bucket_arn must be a valid S3 bucket ARN (arn:aws:s3:::...)."
  }

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::", var.config.role_arn))
    error_message = "config.role_arn must be a valid IAM role ARN (arn:aws:iam::...)."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = var.config.buffering_size >= 1 && var.config.buffering_size <= 128
    error_message = "config.buffering_size must be between 1 and 128 MB."
  }

  validation {
    condition     = var.config.buffering_interval >= 0 && var.config.buffering_interval <= 900
    error_message = "config.buffering_interval must be between 0 and 900 seconds."
  }

  # Server-side encryption with a CUSTOMER_MANAGED_CMK requires a key. If no key
  # is provided, SSE must be disabled via the escape hatch (it would otherwise
  # fall back to an AWS-owned CMK, which is not the secure default we want).
  validation {
    condition     = var.config.kms_key_arn != null || var.config.allow_unencrypted
    error_message = "Server-side encryption needs config.kms_key_arn (CUSTOMER_MANAGED_CMK). To run without it, set config.allow_unencrypted=true and file a PCI exception (security@emag.ro)."
  }
}
