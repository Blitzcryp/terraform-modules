locals {
  module_tags = {
    Module = "atoms/vpc/elastic-ip" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  name_tag = var.config.name == null ? {} : { Name = var.config.name }
}

resource "aws_eip" "this" {
  domain = var.config.domain

  tags = merge(local.tags, local.name_tag)
}
