locals {
  module_tags = {
    Module = "atoms/iam/iam-instance-profile" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# Instance profile: the container that lets EC2 assume a single IAM role via the
# instance metadata service (PCI DSS Req 8 — instances use a scoped role, not
# static keys).
resource "aws_iam_instance_profile" "this" {
  name = var.config.name
  role = var.config.role
  path = var.config.path

  tags = local.tags
}
