locals {
  module_tags = {
    Module = "atoms/vpc/nat-gateway" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  name_tag = var.config.name == null ? {} : { Name = var.config.name }

  # A public NAT gateway requires an EIP allocation; a private one must not have
  # one. The allocation_id is required by config, so it is only attached for the
  # "public" connectivity type.
  allocation_id = var.config.connectivity_type == "public" ? var.config.allocation_id : null
}

resource "aws_nat_gateway" "this" {
  subnet_id         = var.config.subnet_id
  allocation_id     = local.allocation_id
  connectivity_type = var.config.connectivity_type

  tags = merge(local.tags, local.name_tag)
}
