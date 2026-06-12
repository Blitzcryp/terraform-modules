locals {
  module_tags = {
    Module = "atoms/iam/iam-oidc-provider" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# Federated identity provider (OIDC). Enables keyless, short-lived credential
# federation (PCI DSS Req 8 — no long-lived static keys). For IAM OIDC providers
# pointing at well-known IdPs, AWS now manages the thumbprints, so an empty
# thumbprint_list is acceptable.
resource "aws_iam_openid_connect_provider" "this" {
  url             = var.config.url
  client_id_list  = var.config.client_id_list
  thumbprint_list = var.config.thumbprint_list

  tags = local.tags
}
