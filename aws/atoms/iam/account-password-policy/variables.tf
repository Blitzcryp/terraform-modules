variable "config" {
  description = <<-EOT
    Configuration for the account IAM password policy (PCI DSS Req 8: identify &
    authenticate access). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked into the optional() fields, so passing `{}` (or omitting
    config entirely) yields a compliant policy: 14-char minimum, full character
    complexity, 4-cycle reuse prevention and 90-day rotation. This is an
    account-level singleton — there is no required field. Insecure choices
    require flipping an explicit `allow_*` escape hatch.

    NOTE: aws_iam_account_password_policy does NOT support tags. `tags` is
    accepted only so this atom's config shape matches the rest of the library;
    it is not applied to any resource.
  EOT

  type = object({
    # --- Secure-by-default controls (PCI DSS Req 8.3.6 / 8.3.7 / 8.3.9) ---
    minimum_password_length        = optional(number, 14) # PCI 8.3.6: >= 12
    require_lowercase_characters   = optional(bool, true) # PCI 8.3.6 complexity
    require_uppercase_characters   = optional(bool, true) # PCI 8.3.6 complexity
    require_numbers                = optional(bool, true) # PCI 8.3.6 complexity
    require_symbols                = optional(bool, true) # PCI 8.3.6 complexity
    password_reuse_prevention      = optional(number, 4)  # PCI 8.3.7: >= 4 cycles
    max_password_age               = optional(number, 90) # PCI 8.3.9: rotate <= 90 days
    allow_users_to_change_password = optional(bool, true)
    hard_expiry                    = optional(bool, false) # do not lock out expired users by default

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit minimum_password_length below the PCI 8.3.6 floor of 12.
    allow_short_password = optional(bool, false)
  })

  default = {}

  validation {
    condition     = var.config.password_reuse_prevention >= 4
    error_message = "config.password_reuse_prevention must be >= 4 (PCI DSS Req 8.3.7)."
  }

  validation {
    condition     = var.config.max_password_age >= 1 && var.config.max_password_age <= 365
    error_message = "config.max_password_age must be between 1 and 365 days (PCI DSS Req 8.3.9)."
  }
}
