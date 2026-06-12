# Hardened Cognito user pool capability: composes the user-pool, app-client and
# (optionally) hosted-UI domain atoms. Each atom keeps its own PCI-secure
# defaults; the component only threads the high-level knobs and the pool ID
# down by reference. No raw aws_* resources here (CONVENTIONS §1).

module "user_pool" {
  source = "../../atoms/cognito/cognito-user-pool"

  config = {
    name                    = var.config.name
    mfa_configuration       = var.config.mfa_configuration
    password_minimum_length = var.config.password_minimum_length
    # advanced_security_mode, password complexity, MFA TOTP, email recovery and
    # deletion protection all inherit the atom's PCI-secure defaults.
    tags = var.config.tags
  }
}

module "user_pool_client" {
  source = "../../atoms/cognito/cognito-user-pool-client"

  config = {
    name                 = "${var.config.name}-client"
    user_pool_id         = module.user_pool.manifest.id
    generate_secret      = var.config.generate_client_secret
    callback_urls        = var.config.callback_urls
    allowed_oauth_scopes = var.config.allowed_oauth_scopes
    # allowed_oauth_flows (code only), explicit_auth_flows (no password grant),
    # token revocation, prevent_user_existence_errors and token lifetimes all
    # inherit the client atom's PCI-secure defaults.
    tags = var.config.tags
  }
}

module "user_pool_domain" {
  source = "../../atoms/cognito/cognito-user-pool-domain"

  # Only created when a domain is requested.
  count = var.config.domain == null ? 0 : 1

  config = {
    domain          = var.config.domain
    user_pool_id    = module.user_pool.manifest.id
    certificate_arn = var.config.certificate_arn
    tags            = var.config.tags
  }
}
