variable "config" {
  description = <<-EOT
    Configuration for the secrets-manager component (the "Vault" capability).
    All inputs live on this single object. PCI-DSS-compliant defaults are baked
    into the optional() fields: every secret is encrypted with a customer-managed
    KMS key (Req 3) and uses a 30-day recovery window.

    This component composes atoms via module blocks: a kms-key atom (the CMK that
    encrypts the secrets — created unless a `kms_key_arn` is supplied) and one
    secretsmanager-secret atom per entry in the `secrets` map.

    SECURITY: This component never sets secret VALUES. Secret material is
    populated out-of-band by a secrets source or a rotation Lambda — never
    committed to source control (PCI DSS Req 3.5 / Req 8).
  EOT

  type = object({
    # --- Required: prefix for every secret name and the CMK alias. ---
    name_prefix = string

    # --- Encryption (PCI DSS Req 3) ---
    # BYOK: when set, the supplied CMK encrypts all secrets and no kms-key atom
    # is created. When null, a dedicated kms-key atom is created for this vault.
    kms_key_arn = optional(string)

    # --- The secrets to manage. Keyed by logical name; the full secret name is
    # "${name_prefix}/${key}". Values are NEVER set here. ---
    secrets = optional(map(object({
      description         = optional(string)
      rotation_lambda_arn = optional(string)
      rotation_days       = optional(number, 30)
      policy              = optional(string)
    })), {})

    # --- Deletion safety applied to every secret. 7-30 days. ---
    recovery_window_in_days = optional(number, 30)

    # --- Tagging ---
    tags = optional(map(string), {})
  })

  # no `default` here because `name_prefix` is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]{1,400}$", var.config.name_prefix))
    error_message = "config.name_prefix must be 1-400 chars of [a-zA-Z0-9/_+=.@-]."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = var.config.recovery_window_in_days >= 7 && var.config.recovery_window_in_days <= 30
    error_message = "config.recovery_window_in_days must be between 7 and 30."
  }

  validation {
    condition     = alltrue([for k, _ in var.config.secrets : can(regex("^[a-zA-Z0-9/_+=.@-]+$", k))])
    error_message = "each key in config.secrets must contain only [a-zA-Z0-9/_+=.@-]."
  }
}
