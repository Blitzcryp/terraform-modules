variable "config" {
  description = <<-EOT
    Configuration for the standalone EBS volume. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields: the
    volume is encrypted at rest (PCI Req 3) on a gp3 disk. Disabling encryption
    requires flipping the explicit `allow_unencrypted` escape hatch.
  EOT

  type = object({
    # --- Required: the caller must decide this ---
    availability_zone = string # AZ the volume is created in

    # --- Volume shape ---
    size       = optional(number, 20)
    type       = optional(string, "gp3")
    iops       = optional(number) # required/allowed for io1/io2/gp3
    throughput = optional(number) # gp3 only (MiB/s)

    # --- Encryption at rest (PCI DSS Req 3) ---
    encrypted   = optional(bool, true)
    kms_key_arn = optional(string) # CMK; null = AWS-managed EBS key

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # permit encrypted=false
  })

  # no `default` here because `availability_zone` is required

  validation {
    condition     = length(var.config.availability_zone) > 0
    error_message = "config.availability_zone must be a non-empty string (e.g. eu-central-1a)."
  }

  validation {
    condition     = var.config.size >= 1
    error_message = "config.size must be at least 1 GiB."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
