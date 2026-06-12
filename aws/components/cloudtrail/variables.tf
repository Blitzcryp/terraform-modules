variable "config" {
  description = <<-EOT
    Configuration for the cloudtrail component: an encrypted, log-file-validated,
    multi-region CloudTrail trail together with the log store it needs (S3 bucket,
    KMS CMK, CloudWatch log group and the CloudTrail->CWL delivery role). PCI DSS
    Req 10 backbone. PCI-compliant defaults are baked into the optional() fields,
    so the caller only has to supply the required `name`. Insecure choices require
    flipping an explicit `allow_*` escape hatch passed down to the atoms.
  EOT

  type = object({
    # name is REQUIRED: base name for the trail, log bucket, KMS alias, log group
    # and delivery role. The caller must decide it. No default.
    name = string

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---
    kms_key_arn           = optional(string)      # BYOK: if set, no kms-key atom is created
    log_retention_days    = optional(number, 365) # >= 1 year of CloudWatch audit logs
    is_organization_trail = optional(bool, false)
    s3_key_prefix         = optional(string) # null = logs at the bucket root prefix

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
}
