variable "config" {
  description = <<-EOT
    Configuration for the hardened Cognito user pool capability (PCI DSS Req 8:
    identify & authenticate access). Composes a user pool, an app client, and an
    optional hosted-UI domain. All inputs live on this single object. Passing
    only `name` yields a fully hardened stack: MFA enforced (ON) with TOTP,
    advanced security ENFORCED, 14-char complex passwords, a confidential client
    with a generated secret, authorization-code OAuth only (no implicit flow),
    and SRP auth (no password grant). The component surfaces no escape hatches —
    weakening a control means dropping to the underlying atoms directly.
  EOT

  type = object({
    name = string # required — no default

    # --- Pool security knobs (map onto the cognito-user-pool atom) ---
    mfa_configuration       = optional(string, "ON") # OFF | ON | OPTIONAL
    password_minimum_length = optional(number, 14)

    # --- Client knobs (map onto the cognito-user-pool-client atom) ---
    callback_urls          = optional(list(string), [])
    allowed_oauth_scopes   = optional(list(string), ["openid", "email"])
    generate_client_secret = optional(bool, true)

    # --- Optional hosted-UI domain (creates the domain atom only when set) ---
    domain          = optional(string)
    certificate_arn = optional(string)

    tags = optional(map(string), {})
  })
  # no `default` here because `name` is required

  validation {
    condition     = var.config.password_minimum_length >= 12
    error_message = "config.password_minimum_length must be >= 12 (PCI DSS Req 8.3.6). This component enforces the PCI floor with no escape hatch."
  }

  validation {
    condition     = var.config.mfa_configuration == "ON"
    error_message = "config.mfa_configuration must be ON (PCI DSS Req 8.4 / 8.5). This component enforces MFA with no escape hatch; use the cognito-user-pool atom directly for an exception."
  }
}
