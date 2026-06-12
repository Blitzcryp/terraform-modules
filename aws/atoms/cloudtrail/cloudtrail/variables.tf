variable "config" {
  description = <<-EOT
    Configuration for the CloudTrail trail. All inputs live on this single
    object. PCI-DSS-compliant defaults (PCI DSS Req 10: track & monitor all
    access) are baked into the optional() fields, so the caller only has to
    supply the required `name` and `s3_bucket_name`. Insecure choices require
    flipping an explicit `allow_*` escape hatch.

    NOTE: this atom does NOT create the S3 bucket, KMS key, CloudWatch log
    group or delivery role — those are owned by higher layers and their
    names/ARNs are passed in. The atom owns exactly the aws_cloudtrail resource.
  EOT

  type = object({
    # --- Required: the caller must decide these. No defaults. ---
    name           = string # trail name
    s3_bucket_name = string # destination log bucket (created elsewhere; taken as input)

    s3_key_prefix = optional(string) # null = logs at the bucket root prefix

    # --- Secure-by-default controls (PCI DSS Req 10) ---
    is_multi_region_trail         = optional(bool, true) # capture events in every region
    enable_log_file_validation    = optional(bool, true) # tamper-evident digest files (Req 10.5)
    include_global_service_events = optional(bool, true) # IAM/STS/CloudFront etc.
    enable_logging                = optional(bool, true) # start delivering immediately
    is_organization_trail         = optional(bool, false)

    # --- Encryption at rest (PCI DSS Req 3); null = unencrypted (needs hatch) ---
    kms_key_arn = optional(string)

    # --- Optional CloudWatch Logs delivery (real-time monitoring/alerting) ---
    cloud_watch_logs_group_arn = optional(string) # must end with :* (a log-stream-scoped ARN)
    cloud_watch_logs_role_arn  = optional(string)

    # --- Event selectors (data/management events). Free-form to match provider. ---
    event_selectors = optional(any, [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted             = optional(bool, false) # permit kms_key_arn = null
    allow_log_validation_disabled = optional(bool, false) # permit enable_log_file_validation = false
  })

  # no `default` here because name and s3_bucket_name are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.s3_bucket_name) > 0
    error_message = "config.s3_bucket_name must be a non-empty string (the trail's destination log bucket)."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  # A CloudWatch Logs target requires both the group ARN and the delivery role.
  validation {
    condition     = (var.config.cloud_watch_logs_group_arn == null) == (var.config.cloud_watch_logs_role_arn == null)
    error_message = "config.cloud_watch_logs_group_arn and config.cloud_watch_logs_role_arn must be set together (or both null)."
  }
}
