variable "config" {
  description = <<-EOT
    Configuration for the keyless CI/CD OIDC role component (PCI DSS Req 8 — no
    long-lived static keys; CI assumes a role via OIDC). All inputs live on this
    single object. PCI-compliant defaults are baked into the optional() fields,
    so the caller only has to supply the required `role_name` and `subjects`
    (the scoped OIDC subjects allowed to assume the role). Insecure choices
    require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    # role_name is REQUIRED: the identity of the CI/CD role.
    role_name = string
    # subjects is REQUIRED: the scoped OIDC `sub` claims allowed to assume the
    # role, e.g. ["repo:org/repo:ref:refs/heads/main"]. A scoped sub is the
    # whole point of OIDC federation (PCI DSS Req 8).
    subjects = list(string)

    provider_url = optional(string, "token.actions.githubusercontent.com")
    client_ids   = optional(list(string), ["sts.amazonaws.com"])
    thumbprints  = optional(list(string), [])

    # Provider ownership: by default this component creates the OIDC provider.
    # Set create_provider=false and supply provider_arn to reuse an existing one
    # (one OIDC provider per issuer per account).
    create_provider = optional(bool, true)
    provider_arn    = optional(string)

    managed_policy_arns  = optional(list(string), [])
    inline_policies      = optional(map(string), {})
    permissions_boundary = optional(string)
    max_session_duration = optional(number, 3600)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_wildcard_subject = optional(bool, false)
  })

  # no `default` here because role_name and subjects are required

  validation {
    condition     = length(var.config.role_name) > 0
    error_message = "config.role_name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.subjects) > 0
    error_message = "config.subjects must contain at least one OIDC subject (PCI DSS Req 8: scope who may assume the role)."
  }

  # PCI DSS Req 8: reject a wildcard-only subject (e.g. "*" or "repo:*:*") unless
  # allow_wildcard_subject=true. A scoped `sub` is the whole point of OIDC.
  validation {
    condition = var.config.allow_wildcard_subject || alltrue([
      for s in var.config.subjects : length(replace(replace(s, "*", ""), ":", "")) > 0
    ])
    error_message = "config.subjects contains a wildcard-only subject (e.g. \"*\"). A scoped subject is required (PCI DSS Req 8). File a PCI exception (security@emag.ro) and set config.allow_wildcard_subject=true to override."
  }

  # When reusing an existing provider (create_provider=false), provider_arn is
  # required — the trust policy must federate to a concrete provider ARN.
  validation {
    condition     = var.config.create_provider || (var.config.provider_arn != null && try(length(var.config.provider_arn) > 0, false))
    error_message = "config.provider_arn is required when config.create_provider=false (the role must federate to an existing OIDC provider)."
  }

  validation {
    condition     = var.config.max_session_duration >= 3600 && var.config.max_session_duration <= 43200
    error_message = "config.max_session_duration must be between 3600 (1h) and 43200 (12h) seconds."
  }

  validation {
    condition     = length(var.config.client_ids) > 0
    error_message = "config.client_ids must contain at least one audience (client id)."
  }
}
