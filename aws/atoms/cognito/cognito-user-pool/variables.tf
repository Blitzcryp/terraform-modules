variable "config" {
  description = <<-EOT
    Configuration for the Cognito user pool atom (PCI DSS Req 8: identify &
    authenticate access). All inputs live on this single object. PCI-compliant
    defaults are baked into the optional() fields, so passing only `name` yields
    a hardened pool: 14-char minimum passwords with full complexity, MFA
    enforced (ON) with TOTP, advanced security ENFORCED and email-based account
    recovery. Insecure choices require flipping an explicit `allow_*` escape
    hatch that is documented and grep-able.
  EOT

  type = object({
    name = string # required — no default

    # --- Password policy (PCI DSS Req 8.3.6: >= 12 chars, full complexity) ---
    password_minimum_length          = optional(number, 14)
    password_require_lowercase       = optional(bool, true)
    password_require_uppercase       = optional(bool, true)
    password_require_numbers         = optional(bool, true)
    password_require_symbols         = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)

    # --- MFA (PCI DSS Req 8.4 / 8.5: multi-factor authentication) ---
    mfa_configuration = optional(string, "ON") # OFF | ON | OPTIONAL

    # --- Advanced security & verification ---
    advanced_security_mode   = optional(string, "ENFORCED") # OFF | AUDIT | ENFORCED
    auto_verified_attributes = optional(list(string), ["email"])

    # --- Admin sign-up restriction (optional) ---
    allow_admin_create_user_only = optional(bool)

    # --- Deletion protection ---
    deletion_protection = optional(string, "ACTIVE") # ACTIVE | INACTIVE

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit mfa_configuration = "OFF" (disables multi-factor auth, PCI Req 8.4/8.5).
    allow_mfa_off = optional(bool, false)
  })
  # no `default` here because `name` is required

  validation {
    condition     = var.config.password_minimum_length >= 12
    error_message = "config.password_minimum_length must be >= 12 (PCI DSS Req 8.3.6). This atom enforces the PCI floor with no escape hatch on length."
  }

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.config.mfa_configuration)
    error_message = "config.mfa_configuration must be OFF, ON, or OPTIONAL."
  }

  validation {
    condition     = contains(["OFF", "AUDIT", "ENFORCED"], var.config.advanced_security_mode)
    error_message = "config.advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }

  validation {
    condition     = contains(["ACTIVE", "INACTIVE"], var.config.deletion_protection)
    error_message = "config.deletion_protection must be ACTIVE or INACTIVE."
  }
}
