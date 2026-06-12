locals {
  module_tags = {
    Module = "components/network-acl" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# A configured subnet-level stateless firewall (network ACL) for one tier.
# Composes the vpc/network-acl atom only — all validation, default-deny and
# public-exposure preconditions live in the atom; the escape hatches pass
# straight through so an insecure opening stays explicit and auditable.
module "network_acl" {
  source = "../../atoms/vpc/network-acl"

  config = {
    vpc_id     = var.config.vpc_id
    name       = var.config.name
    subnet_ids = var.config.subnet_ids

    ingress_rules = var.config.ingress_rules
    egress_rules  = var.config.egress_rules

    allow_public_ingress     = var.config.allow_public_ingress
    allow_public_admin_ports = var.config.allow_public_admin_ports

    tags = local.tags
  }
}
