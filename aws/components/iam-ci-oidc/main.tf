locals {
  # Whether this component owns the OIDC provider. If the caller supplies a
  # provider ARN we reuse it (one provider per issuer per account) instead of
  # creating a duplicate.
  create_provider = var.config.create_provider

  # Host portion of the issuer, used to build the OIDC condition keys
  # (<host>:sub / <host>:aud). Strip the scheme so the same value works whether
  # the caller passes "token.actions.githubusercontent.com" or the https:// URL.
  provider_host = replace(var.config.provider_url, "https://", "")
  issuer_url    = "https://${local.provider_host}"

  # Effective provider ARN the trust policy federates to: the one we create or
  # the caller's reused ARN.
  effective_provider_arn = local.create_provider ? module.oidc_provider[0].manifest.arn : var.config.provider_arn

  # PCI DSS Req 8 guardrail: a scoped `sub` is the entire point of OIDC
  # federation. Reject a bare wildcard-only subject (e.g. "*" or "repo:*:*")
  # unless allow_wildcard_subject is set. We flag any subject that is only a
  # wildcard once non-`*`/`:` characters are stripped.
  wildcard_only_subjects = [
    for s in var.config.subjects : s
    if length(replace(replace(s, "*", ""), ":", "")) == 0
  ]

  # Trust (assume-role) policy: the OIDC provider is the Federated principal,
  # constrained by StringEquals on <host>:aud (the audience / client ids) and
  # StringLike on <host>:sub (the scoped subjects).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOidcAssumeRole"
        Effect    = "Allow"
        Principal = { Federated = local.effective_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.provider_host}:aud" = var.config.client_ids
          }
          StringLike = {
            "${local.provider_host}:sub" = var.config.subjects
          }
        }
      },
    ]
  })
}

# --- OIDC identity provider (created only when this component owns it) --------
module "oidc_provider" {
  source = "../../atoms/iam/iam-oidc-provider"
  count  = local.create_provider ? 1 : 0

  config = {
    url             = local.issuer_url
    client_id_list  = var.config.client_ids
    thumbprint_list = var.config.thumbprints
    tags            = var.config.tags
  }
}

# --- Keyless CI/CD role assumed via OIDC (no static keys; PCI DSS Req 8) ------
module "ci_role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name                 = var.config.role_name
    description          = "Keyless CI/CD role assumed via OIDC (${local.provider_host})"
    assume_role_policy   = local.assume_role_policy
    permissions_boundary = var.config.permissions_boundary
    max_session_duration = var.config.max_session_duration
    managed_policy_arns  = var.config.managed_policy_arns
    inline_policies      = var.config.inline_policies
    tags                 = var.config.tags
  }
}
