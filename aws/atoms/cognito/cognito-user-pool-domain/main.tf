locals {
  # Module-identity tag (CONVENTIONS §5). NOTE: aws_cognito_user_pool_domain is
  # not a taggable resource, so these are not applied — kept only so this atom's
  # config interface matches every other atom (config.tags is accepted).
  module_tags = {
    Module = "atoms/cognito/cognito-user-pool-domain"
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.config.domain
  user_pool_id = var.config.user_pool_id

  # Custom domains are served over an ACM (us-east-1) certificate; omit for a
  # Cognito-prefix domain (still TLS-terminated by the Cognito-managed endpoint).
  certificate_arn = var.config.certificate_arn
}
