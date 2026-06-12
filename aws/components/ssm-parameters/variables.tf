variable "config" {
  description = <<-EOT
    Configuration for the ssm-parameters component (a set of encrypted
    parameters). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked in: every parameter is a SecureString encrypted with a
    customer-managed KMS key (Req 3 / Req 8).

    This component composes atoms via module blocks: a kms-key atom (the CMK that
    encrypts every parameter — created unless a `kms_key_arn` is supplied) and
    one ssm-parameter atom per entry in the `parameters` map.

    SECURITY: parameter VALUES must never be hardcoded secrets in source control.
    Supply them out-of-band (CI/CD secret store) and use <YOUR_PARAMETER_VALUE>
    placeholders in examples (PCI DSS Req 3 / Req 8).
  EOT

  type = object({
    # --- Required: prefix for every parameter name and the CMK alias. ---
    name_prefix = string

    # --- Encryption (PCI DSS Req 3) ---
    # BYOK: when set, the supplied CMK encrypts all parameters and no kms-key
    # atom is created. When null, a dedicated kms-key atom is created.
    kms_key_arn = optional(string)

    # --- The parameters to manage. Keyed by logical name; the full parameter
    # name is "${name_prefix}/${key}". Every parameter is a SecureString. ---
    parameters = optional(map(object({
      value       = string # SECURITY: never hardcode a real secret here
      description = optional(string)
      tier        = optional(string, "Standard")
    })), {})

    # --- Tagging ---
    tags = optional(map(string), {})
  })

  sensitive = true # config carries parameter values

  # no `default` here because `name_prefix` is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_.-]{1,400}$", var.config.name_prefix))
    error_message = "config.name_prefix must be 1-400 chars of [a-zA-Z0-9/_.-]."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = alltrue([for k, _ in var.config.parameters : can(regex("^[a-zA-Z0-9/_.-]+$", k))])
    error_message = "each key in config.parameters must contain only [a-zA-Z0-9/_.-]."
  }
}
