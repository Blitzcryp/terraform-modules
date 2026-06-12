variable "config" {
  description = <<-EOT
    Configuration for the Kinesis data stream. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    the caller only has to supply the required `name` to get a KMS-encrypted,
    on-demand stream. Insecure choices require flipping an explicit `allow_*`
    escape hatch.
  EOT

  type = object({
    # name is REQUIRED: the caller must decide the stream name. No default.
    name = string

    # --- Capacity ---
    # stream_mode ON_DEMAND (default) auto-scales and must NOT set shard_count.
    # PROVISIONED requires shard_count.
    stream_mode = optional(string, "ON_DEMAND")
    shard_count = optional(number) # null for ON_DEMAND; required for PROVISIONED

    # --- Secure-by-default controls (PCI DSS Req 3: protect stored data) ---
    retention_period = optional(number, 24) # hours, 24-8760
    kms_key_arn      = optional(string)     # BYO CMK; null = AWS-managed kinesis key

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # sets encryption_type = NONE
  })

  # no `default` here because name is required

  validation {
    condition     = contains(["ON_DEMAND", "PROVISIONED"], var.config.stream_mode)
    error_message = "config.stream_mode must be ON_DEMAND or PROVISIONED."
  }

  validation {
    condition     = var.config.retention_period >= 24 && var.config.retention_period <= 8760
    error_message = "config.retention_period must be between 24 and 8760 hours."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
