locals {
  # Module-identity tag (CONVENTIONS §5). NOTE: aws_cognito_user_pool_client is
  # not a taggable resource, so these are not applied — kept only so this atom's
  # config interface matches every other atom (config.tags is accepted).
  module_tags = {
    Module = "atoms/cognito/cognito-user-pool-client"
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cognito_user_pool_client" "this" {
  name         = var.config.name
  user_pool_id = var.config.user_pool_id

  generate_secret = var.config.generate_secret

  # --- OAuth / hosted-UI (no implicit flow; tokens never returned in URL) ---
  allowed_oauth_flows                  = var.config.allowed_oauth_flows
  allowed_oauth_scopes                 = var.config.allowed_oauth_scopes
  allowed_oauth_flows_user_pool_client = length(var.config.allowed_oauth_flows) > 0
  callback_urls                        = var.config.callback_urls
  supported_identity_providers         = ["COGNITO"]

  # --- Auth flows (SRP by default; USER_PASSWORD_AUTH gated by escape hatch) ---
  explicit_auth_flows = var.config.explicit_auth_flows

  # --- Token lifetimes ---
  access_token_validity  = var.config.access_token_validity
  id_token_validity      = var.config.id_token_validity
  refresh_token_validity = var.config.refresh_token_validity

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # --- Threat protection (PCI DSS Req 8) ---
  prevent_user_existence_errors = var.config.prevent_user_existence_errors
  enable_token_revocation       = var.config.enable_token_revocation

  # The password-based grant (ALLOW_USER_PASSWORD_AUTH) sends raw credentials to
  # the token endpoint instead of using SRP; enabling it must be intentional.
  lifecycle {
    precondition {
      condition     = !contains(var.config.explicit_auth_flows, "ALLOW_USER_PASSWORD_AUTH") || var.config.allow_password_auth
      error_message = "explicit_auth_flows includes ALLOW_USER_PASSWORD_AUTH without config.allow_password_auth=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
