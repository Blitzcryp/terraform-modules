locals {
  # local.tags is kept for uniformity with other atoms, but
  # aws_iam_account_password_policy does NOT support tags — the account password
  # policy is not a taggable AWS resource. The merged tags are computed here only
  # so this atom's config shape matches the rest of the library; they are not
  # applied to any resource.
  module_tags = {
    Module = "atoms/iam/account-password-policy" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_iam_account_password_policy" "this" {
  # checkov:skip=CKV_AWS_11: require_lowercase_characters defaults to true via
  # checkov:skip=CKV_AWS_15: config.require_uppercase_characters, require_numbers and
  # checkov:skip=CKV_AWS_12: require_symbols (each optional(bool, true)); checkov cannot
  # checkov:skip=CKV_AWS_14: statically resolve these through the config object, but the
  # checkov:skip=CKV_AWS_9: secure defaults (full complexity, 90-day max age) are enforced
  # checkov:skip=CKV_AWS_13: password_reuse_prevention defaults to 4 (PCI Req 8.3.7) via the
  # config object, which checkov cannot statically resolve; enforced by the secure_defaults test.
  # by the secure_defaults test. Relaxing them requires editing the auditable config
  # defaults / escape hatch (PCI DSS Req 8.3.6 / 8.3.9).
  minimum_password_length        = var.config.minimum_password_length
  require_lowercase_characters   = var.config.require_lowercase_characters
  require_uppercase_characters   = var.config.require_uppercase_characters
  require_numbers                = var.config.require_numbers
  require_symbols                = var.config.require_symbols
  password_reuse_prevention      = var.config.password_reuse_prevention
  max_password_age               = var.config.max_password_age
  allow_users_to_change_password = var.config.allow_users_to_change_password
  hard_expiry                    = var.config.hard_expiry

  # Strong password length must be intentional to weaken (PCI DSS Req 8.3.6:
  # passwords must be at least 12 characters).
  lifecycle {
    precondition {
      condition     = var.config.minimum_password_length >= 12 || var.config.allow_short_password
      error_message = "minimum_password_length below 12 without config.allow_short_password=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
