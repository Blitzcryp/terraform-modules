locals {
  module_tags = {
    Module = "atoms/vpc/network-acl" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  public_cidrs = ["0.0.0.0/0", "::/0"]
  admin_ports  = [22, 3389]

  # An ALLOW ingress rule whose source is the whole internet.
  public_allow_ingress_rules = [
    for r in var.config.ingress_rules : r
    if r.rule_action == "allow" && contains(local.public_cidrs, coalesce(r.cidr_block, r.ipv6_cidr_block, "none"))
  ]

  # Public ALLOW ingress rules that also expose an admin port (SSH/RDP). A rule
  # exposes an admin port when its port range covers 22 or 3389, or when it
  # opens all protocols ("-1") / has no port bounds.
  public_admin_allow_ingress_rules = [
    for r in local.public_allow_ingress_rules : r
    if contains(["-1", "0"], r.protocol) || r.from_port == null || r.to_port == null || anytrue([
      for p in local.admin_ports : r.from_port <= p && r.to_port >= p
    ])
  ]
}

resource "aws_network_acl" "this" {
  vpc_id     = var.config.vpc_id
  subnet_ids = var.config.subnet_ids

  # Rules are managed exclusively by the separate aws_network_acl_rule resources
  # below — no inline ingress/egress blocks. A network ACL is default-deny: any
  # traffic not matched by an explicit numbered rule is dropped (PCI DSS Req 1).
  tags = merge(local.tags, var.config.name == null ? {} : { Name = var.config.name })

  lifecycle {
    # Block any ALLOW rule open to 0.0.0.0/0 or ::/0 unless intentionally opted in.
    precondition {
      condition     = length(local.public_allow_ingress_rules) == 0 || var.config.allow_public_ingress
      error_message = "An ingress ALLOW rule is open to 0.0.0.0/0 or ::/0 without config.allow_public_ingress=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # Block public admin ports (22/SSH, 3389/RDP) unless intentionally opted in.
    precondition {
      condition     = length(local.public_admin_allow_ingress_rules) == 0 || var.config.allow_public_admin_ports
      error_message = "An admin port (22/SSH or 3389/RDP) is opened to 0.0.0.0/0 or ::/0 without config.allow_public_admin_ports=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

resource "aws_network_acl_rule" "ingress" {
  count = length(var.config.ingress_rules)

  network_acl_id = aws_network_acl.this.id
  egress         = false

  rule_number = var.config.ingress_rules[count.index].rule_number
  protocol    = var.config.ingress_rules[count.index].protocol
  rule_action = var.config.ingress_rules[count.index].rule_action

  cidr_block      = var.config.ingress_rules[count.index].cidr_block
  ipv6_cidr_block = var.config.ingress_rules[count.index].ipv6_cidr_block
  from_port       = var.config.ingress_rules[count.index].from_port
  to_port         = var.config.ingress_rules[count.index].to_port
  icmp_type       = var.config.ingress_rules[count.index].icmp_type
  icmp_code       = var.config.ingress_rules[count.index].icmp_code
}

resource "aws_network_acl_rule" "egress" {
  count = length(var.config.egress_rules)

  network_acl_id = aws_network_acl.this.id
  egress         = true

  rule_number = var.config.egress_rules[count.index].rule_number
  protocol    = var.config.egress_rules[count.index].protocol
  rule_action = var.config.egress_rules[count.index].rule_action

  cidr_block      = var.config.egress_rules[count.index].cidr_block
  ipv6_cidr_block = var.config.egress_rules[count.index].ipv6_cidr_block
  from_port       = var.config.egress_rules[count.index].from_port
  to_port         = var.config.egress_rules[count.index].to_port
  icmp_type       = var.config.egress_rules[count.index].icmp_type
  icmp_code       = var.config.egress_rules[count.index].icmp_code
}
