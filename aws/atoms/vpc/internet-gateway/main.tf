locals {
  module_tags = {
    Module = "atoms/vpc/internet-gateway" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  name_tag = var.config.name == null ? {} : { Name = var.config.name }
}

resource "aws_internet_gateway" "this" {
  vpc_id = var.config.vpc_id

  tags = merge(local.tags, local.name_tag)
}
