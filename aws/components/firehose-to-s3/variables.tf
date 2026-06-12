variable "config" {
  description = <<-EOT
    Configuration for the firehose-to-s3 component: an encrypted Kinesis Data
    Firehose delivery stream that lands records in a private, KMS-encrypted S3
    bucket, with delivery errors captured in a KMS-encrypted CloudWatch log
    group. The component owns and wires together the delivery bucket, the CMK
    (unless a BYO key is supplied), the error log group, the firehose delivery
    IAM role and the firehose stream itself. PCI DSS Req 3 (encryption) and Req
    10 (logging) backbone. PCI-compliant defaults are baked into the optional()
    fields, so the caller only has to supply the required `name`.
  EOT

  type = object({
    # name is REQUIRED: base name for the stream, delivery bucket, KMS alias,
    # error log group and delivery role. The caller must decide it. No default.
    name = string

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) -
    kms_key_arn        = optional(string)      # BYOK: if set, no kms-key atom is created
    buffering_size     = optional(number, 5)   # MB, 1-128
    buffering_interval = optional(number, 300) # seconds, 0-900
    prefix             = optional(string, "data/")
    log_retention_days = optional(number, 365) # >= 1 year of CloudWatch error logs

    tags = optional(map(string), {})
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
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
}
