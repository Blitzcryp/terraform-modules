locals {
  module_tags = {
    Module = "atoms/vpc/security-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  public_cidrs = ["0.0.0.0/0", "::/0"]
  admin_ports  = [22, 3389]

  # Ingress rules whose source is the whole internet.
  public_ingress_rules = [
    for r in var.config.ingress_rules : r
    if contains(local.public_cidrs, coalesce(r.cidr_ipv4, r.cidr_ipv6, "none"))
  ]

  # Public ingress rules that also expose an admin port (SSH/RDP). A rule
  # exposes an admin port when its port range covers 22 or 3389, or when it
  # opens all protocols/ports (ip_protocol "-1" or no port bounds).
  public_admin_ingress_rules = [
    for r in local.public_ingress_rules : r
    if r.ip_protocol == "-1" || r.from_port == null || r.to_port == null || anytrue([
      for p in local.admin_ports : r.from_port <= p && r.to_port >= p
    ])
  ]
}

resource "aws_security_group" "this" {
  name        = var.config.name
  description = var.config.description
  vpc_id      = var.config.vpc_id

  # Declaring both rule sets as empty strips AWS's implicit allow-all egress
  # rule (PCI DSS Req 1 — no traffic is permitted unless explicitly declared).
  # All actual rules are managed by the separate rule resources below.
  ingress = []
  egress  = []

  tags = local.tags

  lifecycle {
    # Block any 0.0.0.0/0 or ::/0 ingress unless intentionally opted in.
    precondition {
      condition     = length(local.public_ingress_rules) == 0 || var.config.allow_public_ingress
      error_message = "Ingress open to 0.0.0.0/0 or ::/0 without config.allow_public_ingress=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # Block public admin ports (22/SSH, 3389/RDP) unless intentionally opted in.
    precondition {
      condition     = length(local.public_admin_ingress_rules) == 0 || var.config.allow_public_admin_ports
      error_message = "Admin port (22/SSH or 3389/RDP) open to 0.0.0.0/0 or ::/0 without config.allow_public_admin_ports=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  count = length(var.config.ingress_rules)

  security_group_id = aws_security_group.this.id
  description       = var.config.ingress_rules[count.index].description
  ip_protocol       = var.config.ingress_rules[count.index].ip_protocol
  from_port         = var.config.ingress_rules[count.index].from_port
  to_port           = var.config.ingress_rules[count.index].to_port

  cidr_ipv4                    = var.config.ingress_rules[count.index].cidr_ipv4
  cidr_ipv6                    = var.config.ingress_rules[count.index].cidr_ipv6
  referenced_security_group_id = var.config.ingress_rules[count.index].referenced_security_group_id
  prefix_list_id               = var.config.ingress_rules[count.index].prefix_list_id

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  count = length(var.config.egress_rules)

  security_group_id = aws_security_group.this.id
  description       = var.config.egress_rules[count.index].description
  ip_protocol       = var.config.egress_rules[count.index].ip_protocol
  from_port         = var.config.egress_rules[count.index].from_port
  to_port           = var.config.egress_rules[count.index].to_port

  cidr_ipv4                    = var.config.egress_rules[count.index].cidr_ipv4
  cidr_ipv6                    = var.config.egress_rules[count.index].cidr_ipv6
  referenced_security_group_id = var.config.egress_rules[count.index].referenced_security_group_id
  prefix_list_id               = var.config.egress_rules[count.index].prefix_list_id

  tags = local.tags
}
