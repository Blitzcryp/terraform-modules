variable "config" {
  description = <<-EOT
    Configuration for the SSM Parameter Store atom. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields: the parameter is a SecureString encrypted with a customer-managed
    KMS key (Req 3 / Req 8). Storing plaintext (String/StringList) requires
    flipping the explicit `allow_plaintext` escape hatch.

    SECURITY: the parameter VALUE must never be a hardcoded secret in source
    control. Supply it from a secrets source / CI variable and use a
    <YOUR_PARAMETER_VALUE> placeholder in examples (PCI DSS Req 3 / Req 8).
  EOT

  type = object({
    # --- Required ---
    name  = string
    value = string # SECURITY: never hardcode a real secret here

    # --- Type (PCI DSS Req 3): SecureString by default ---
    type = optional(string, "SecureString") # String | StringList | SecureString

    # --- Encryption: CMK used to encrypt a SecureString (Req 3). ---
    kms_key_arn = optional(string)

    description = optional(string)
    tier        = optional(string, "Standard") # Standard | Advanced | Intelligent-Tiering

    # --- Tagging ---
    tags = optional(map(string), {})

    # --- Escape hatch: permit plaintext String/StringList (no encryption). ---
    allow_plaintext = optional(bool, false)
  })

  sensitive = true # config carries the parameter value

  # no `default` here because name/value are required

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.config.type)
    error_message = "config.type must be String, StringList, or SecureString."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = contains(["Standard", "Advanced", "Intelligent-Tiering"], var.config.tier)
    error_message = "config.tier must be Standard, Advanced, or Intelligent-Tiering."
  }
}
