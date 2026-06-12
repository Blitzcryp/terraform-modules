locals {
  module_tags = {
    Module = "atoms/elasticache/elasticache-subnet-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_elasticache_subnet_group" "this" {
  name        = var.config.name
  subnet_ids  = var.config.subnet_ids
  description = var.config.description

  tags = local.tags
}
