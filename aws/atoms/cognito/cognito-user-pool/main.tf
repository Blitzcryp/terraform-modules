locals {
  module_tags = {
    Module = "atoms/cognito/cognito-user-pool" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cognito_user_pool" "this" {
  name = var.config.name

  # --- Password policy (PCI DSS Req 8.3.6: strong, complex passwords) ---
  password_policy {
    minimum_length                   = var.config.password_minimum_length
    require_lowercase                = var.config.password_require_lowercase
    require_uppercase                = var.config.password_require_uppercase
    require_numbers                  = var.config.password_require_numbers
    require_symbols                  = var.config.password_require_symbols
    temporary_password_validity_days = var.config.temporary_password_validity_days
  }

  # --- MFA (PCI DSS Req 8.4 / 8.5: multi-factor authentication) ---
  mfa_configuration = var.config.mfa_configuration

  software_token_mfa_configuration {
    enabled = true
  }

  # --- Advanced security: threat protection, compromised-credential checks ---
  user_pool_add_ons {
    advanced_security_mode = var.config.advanced_security_mode
  }

  auto_verified_attributes = var.config.auto_verified_attributes

  # --- Self-service recovery via verified email only (no SMS fallback) ---
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  dynamic "admin_create_user_config" {
    for_each = var.config.allow_admin_create_user_only == null ? [] : [1]
    content {
      allow_admin_create_user_only = var.config.allow_admin_create_user_only
    }
  }

  deletion_protection = var.config.deletion_protection

  tags = local.tags

  # MFA is a PCI Req 8.4/8.5 control; disabling it must be intentional & auditable.
  lifecycle {
    precondition {
      condition     = var.config.mfa_configuration != "OFF" || var.config.allow_mfa_off
      error_message = "mfa_configuration=OFF without config.allow_mfa_off=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
