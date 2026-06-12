locals {
  module_tags = {
    Module = "atoms/iam/iam-user" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# IAM user identity ONLY.
#
# SECURITY / PCI DSS Req 8 — this atom intentionally does NOT manage:
#   * aws_iam_access_key       (long-lived static programmatic credentials)
#   * aws_iam_user_login_profile (console password)
# Long-lived keys are discouraged: prefer IAM roles, SSO, or OIDC/Web Identity
# federation. Where a static credential is genuinely required it must be issued
# out-of-band and NEVER stored in source control or Terraform state.
resource "aws_iam_user" "this" {
  # checkov:skip=CKV_AWS_273: This atom's sole purpose is to manage an IAM user.
  # SSO/identity-federation is the preferred access path (PCI DSS Req 8) and is
  # an org/account-level control documented in the README; where a discrete IAM
  # user is genuinely required this module provisions ONLY the identity, never
  # static keys or a console password.
  name                 = var.config.name
  path                 = var.config.path
  permissions_boundary = var.config.permissions_boundary
  force_destroy        = var.config.force_destroy

  tags = local.tags
}
