variable "config" {
  description = <<-EOT
    Configuration for the Cognito user pool client atom (PCI DSS Req 8: identify
    & authenticate access). All inputs live on this single object. PCI-compliant
    defaults are baked into the optional() fields, so passing only `name` and
    `user_pool_id` yields a hardened client: a client secret is generated, only
    the OAuth authorization-code flow is allowed (no insecure implicit flow),
    token revocation is enabled, user-existence errors are masked, and the
    explicit auth flows exclude the password-based grant (USER_PASSWORD_AUTH).
    Enabling the password grant requires flipping the explicit, grep-able
    `allow_password_auth` escape hatch.
  EOT

  type = object({
    name         = string # required — no default
    user_pool_id = string # required — no default

    # --- Client secret (confidential clients) ---
    generate_secret = optional(bool, true)

    # --- OAuth / hosted-UI ---
    callback_urls        = optional(list(string), [])
    allowed_oauth_flows  = optional(list(string), ["code"]) # never "implicit" (PCI: no token in URL fragment)
    allowed_oauth_scopes = optional(list(string), ["openid", "email"])

    # --- Auth flows (no USER_PASSWORD_AUTH by default; SRP only) ---
    explicit_auth_flows = optional(list(string), ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"])

    # --- Token lifetimes ---
    access_token_validity  = optional(number, 60) # minutes
    id_token_validity      = optional(number, 60) # minutes
    refresh_token_validity = optional(number, 30) # days

    # --- Threat protection ---
    prevent_user_existence_errors = optional(string, "ENABLED") # ENABLED | LEGACY
    enable_token_revocation       = optional(bool, true)

    # aws_cognito_user_pool_client is NOT a taggable resource. `tags` is accepted
    # for interface uniformity across atoms but is intentionally not applied to
    # any resource here. Documented per CONVENTIONS §5.
    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit the password-based grant (ALLOW_USER_PASSWORD_AUTH) in
    # explicit_auth_flows. Sends raw credentials to the token endpoint instead
    # of using SRP; weakens PCI Req 8 protections.
    allow_password_auth = optional(bool, false)
  })
  # no `default` here because `name` and `user_pool_id` are required

  validation {
    condition     = !contains(var.config.allowed_oauth_flows, "implicit")
    error_message = "config.allowed_oauth_flows must not include \"implicit\" (PCI DSS Req 8: the implicit grant returns tokens in the URL fragment). Use \"code\". This atom has no escape hatch for the implicit flow."
  }

  validation {
    condition     = contains(["ENABLED", "LEGACY"], var.config.prevent_user_existence_errors)
    error_message = "config.prevent_user_existence_errors must be ENABLED or LEGACY."
  }
}
