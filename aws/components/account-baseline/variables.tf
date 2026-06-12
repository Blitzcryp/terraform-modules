variable "config" {
  description = <<-EOT
    Configuration for the account-baseline component (account-wide security
    guardrails, PCI DSS Req 8 access control). All inputs live on this single
    object. PCI-compliant defaults are baked into the optional() fields, so
    passing `{}` (or omitting config entirely) yields a compliant baseline. This
    component is structured so additional account-level atoms can be composed in
    later. Insecure choices require flipping an explicit `allow_*` escape hatch
    that is passed down to the underlying atoms.

    NOTE: the account password policy is not a taggable AWS resource. `tags` is
    accepted for interface uniformity and threaded to atoms that support it.
  EOT

  type = object({
    # --- Secure-by-default controls (PCI DSS Req 8.3.6 / 8.3.7 / 8.3.9) ---
    password_minimum_length   = optional(number, 14) # PCI 8.3.6: >= 12
    password_max_age          = optional(number, 90) # PCI 8.3.9: rotate <= 90 days
    password_reuse_prevention = optional(number, 4)  # PCI 8.3.7: >= 4 cycles
    require_symbols           = optional(bool, true) # PCI 8.3.6 complexity

    tags = optional(map(string), {})
  })

  default = {}

  validation {
    condition     = var.config.password_minimum_length >= 12
    error_message = "config.password_minimum_length must be >= 12 (PCI DSS Req 8.3.6). This component does not expose an escape hatch; weaken it on the atom directly if a documented exception applies."
  }

  validation {
    condition     = var.config.password_max_age >= 1 && var.config.password_max_age <= 365
    error_message = "config.password_max_age must be between 1 and 365 days (PCI DSS Req 8.3.9)."
  }

  validation {
    condition     = var.config.password_reuse_prevention >= 4
    error_message = "config.password_reuse_prevention must be >= 4 (PCI DSS Req 8.3.7)."
  }
}
