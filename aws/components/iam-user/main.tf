locals {
  module_tags = {
    Module = "components/iam-user" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# A single secure IAM user. This component composes the iam-user atom only — it
# deliberately creates no static access keys and no console login profile
# (PCI DSS Req 8). Group membership is handled by the iam-group component.
module "user" {
  source = "../../atoms/iam/iam-user"

  config = {
    name                 = var.config.name
    path                 = var.config.path
    permissions_boundary = var.config.permissions_boundary
    force_destroy        = var.config.force_destroy
    tags                 = local.tags
  }
}
