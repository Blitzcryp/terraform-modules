locals {
  module_tags = {
    Module = "atoms/vpc/subnet" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_subnet" "this" {
  vpc_id                  = var.config.vpc_id
  cidr_block              = var.config.cidr_block
  availability_zone       = var.config.availability_zone
  map_public_ip_on_launch = var.config.map_public_ip_on_launch

  tags = merge(local.tags, { Name = var.config.name })

  # Automatic public IP assignment must be intentional to enable (PCI DSS Req 1).
  lifecycle {
    precondition {
      condition     = !var.config.map_public_ip_on_launch || var.config.allow_auto_public_ip
      error_message = "map_public_ip_on_launch=true without config.allow_auto_public_ip=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
