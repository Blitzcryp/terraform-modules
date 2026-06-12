variable "config" {
  description = <<-EOT
    Configuration for the KMS key. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so passing
    `{}` (or omitting config entirely) yields a compliant key. Insecure choices
    require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    description = optional(string, "Managed by terraform (atoms/kms-key)")
    alias       = optional(string) # without the 'alias/' prefix; null = no alias

    # --- Secure-by-default controls (PCI DSS Req 3: protect stored data) ---
    enable_key_rotation     = optional(bool, true) # PCI 3.6.4 / 3.7
    deletion_window_in_days = optional(number, 30) # 7-30; longer = safer
    multi_region            = optional(bool, false)
    key_usage               = optional(string, "ENCRYPT_DECRYPT")
    key_spec                = optional(string, "SYMMETRIC_DEFAULT")
    policy                  = optional(string) # null = least-privilege default policy
    tags                    = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_rotation_disabled = optional(bool, false)
  })

  default = {}

  validation {
    condition     = var.config.alias == null || can(regex("^[a-zA-Z0-9/_-]+$", var.config.alias))
    error_message = "config.alias may contain only alphanumerics and the characters / _ - (no 'alias/' prefix)."
  }

  validation {
    condition     = var.config.deletion_window_in_days >= 7 && var.config.deletion_window_in_days <= 30
    error_message = "config.deletion_window_in_days must be between 7 and 30."
  }

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC"], var.config.key_usage)
    error_message = "config.key_usage must be ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC."
  }
}
