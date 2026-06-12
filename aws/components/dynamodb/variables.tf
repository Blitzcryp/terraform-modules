variable "config" {
  description = <<-EOT
    Configuration for the dynamodb component (an encrypted DynamoDB table
    capability). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked into the optional() fields: the table is encrypted at rest
    with a customer-managed KMS key (Req 3), point-in-time recovery is on, and
    deletion protection is on.

    This component composes atoms via module blocks: a kms-key atom (the CMK that
    encrypts the table — created unless a `kms_key_arn` is supplied) and a
    dynamodb-table atom.
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
    global_secondary_indexes = optional(list(any), [])
    ttl_attribute            = optional(string)
    stream_enabled           = optional(bool, false)
    stream_view_type         = optional(string)

    # --- Encryption (PCI DSS Req 3) ---
    # BYOK: when set, the supplied CMK encrypts the table and no kms-key atom is
    # created. When null, a dedicated kms-key atom is created for this table.
    kms_key_arn = optional(string)

    # --- Tagging ---
    tags = optional(map(string), {})
  })

  # no `default` here because name/hash_key/attributes are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.config.name))
    error_message = "config.name must be 3-255 chars of [a-zA-Z0-9_.-]."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.config.billing_mode)
    error_message = "config.billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}
