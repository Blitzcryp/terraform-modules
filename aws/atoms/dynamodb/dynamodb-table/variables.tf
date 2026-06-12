variable "config" {
  description = <<-EOT
    Configuration for the DynamoDB table atom. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields:
    encryption at rest with a customer-managed key (Req 3), point-in-time
    recovery on, and deletion protection on. Insecure choices require flipping an
    explicit `allow_*` escape hatch.
  EOT

  type = object({
    # --- Required ---
    name     = string
    hash_key = string
    attributes = list(object({
      name = string
      type = string # S | N | B
    }))

    # --- Optional schema ---
    range_key                = optional(string)
    billing_mode             = optional(string, "PAY_PER_REQUEST")
    read_capacity            = optional(number) # required only for PROVISIONED
    write_capacity           = optional(number) # required only for PROVISIONED
    global_secondary_indexes = optional(list(any), [])
    local_secondary_indexes  = optional(list(any), [])
    ttl_attribute            = optional(string) # null = TTL disabled
    stream_enabled           = optional(bool, false)
    stream_view_type         = optional(string) # NEW_IMAGE | OLD_IMAGE | NEW_AND_OLD_IMAGES | KEYS_ONLY

    # --- Point-in-time recovery (PCI: data durability) ---
    enable_point_in_time_recovery = optional(bool, true)

    # --- Encryption at rest (PCI DSS Req 3) ---
    # When set, a customer-managed KMS key encrypts the table. When null and the
    # AWS-owned-key escape hatch is flipped, the table uses the AWS-owned key.
    kms_key_arn = optional(string)

    # --- Tagging ---
    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_aws_owned_key = optional(bool, false) # permit no CMK (AWS-owned key)
    allow_no_pitr       = optional(bool, false) # permit point-in-time recovery off
    allow_deletion      = optional(bool, false) # permit deletion protection off

    # --- Deletion safety (PCI: protect production data) ---
    deletion_protection_enabled = optional(bool, true)
  })

  # no `default` here because name/hash_key/attributes are required

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.config.billing_mode)
    error_message = "config.billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }

  validation {
    condition = var.config.billing_mode != "PROVISIONED" || (
      var.config.read_capacity != null && var.config.write_capacity != null
    )
    error_message = "config.read_capacity and config.write_capacity are required when billing_mode is PROVISIONED."
  }

  validation {
    condition     = alltrue([for a in var.config.attributes : contains(["S", "N", "B"], a.type)])
    error_message = "each attribute type in config.attributes must be S, N, or B."
  }

  validation {
    condition     = !var.config.stream_enabled || var.config.stream_view_type != null
    error_message = "config.stream_view_type is required when config.stream_enabled is true."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
