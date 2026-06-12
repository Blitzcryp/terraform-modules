variable "config" {
  description = <<-EOT
    Configuration for the network-acl component: a configured subnet-level
    stateless firewall for one network tier (e.g. a private tier). `name` and
    `vpc_id` are required. A network ACL is DEFAULT-DENY and STATELESS — every
    opening is an explicit numbered rule, and return traffic needs its own rule
    (typically the ephemeral port range 1024-65535). PCI-DSS-compliant defaults:
    no rules until you add them (deny everything), and any opening to the public
    internet requires flipping an explicit `allow_*` escape hatch (passthrough to
    the underlying atom). See the README for recommended per-tier baselines.
  EOT

  type = object({
    name   = string # required — the caller must decide this
    vpc_id = string # required — the caller must decide this

    # Subnets this tier's NACL is associated with (moves them off the default NACL).
    subnet_ids = optional(list(string), [])

    # Numbered, explicit-action rules. See the atom for field semantics:
    # tcp/udp need from_port+to_port; icmp uses icmp_type+icmp_code; "-1" needs
    # neither; each rule sets exactly one of cidr_block / ipv6_cidr_block.
    ingress_rules = optional(list(object({
      rule_number     = number
      protocol        = string
      rule_action     = string
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
      from_port       = optional(number)
      to_port         = optional(number)
      icmp_type       = optional(number)
      icmp_code       = optional(number)
    })), [])

    egress_rules = optional(list(object({
      rule_number     = number
      protocol        = string
      rule_action     = string
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
      from_port       = optional(number)
      to_port         = optional(number)
      icmp_type       = optional(number)
      icmp_code       = optional(number)
    })), [])

    tags = optional(map(string), {})

    # --- Escape hatches (passthrough to the atom) ----------------------
    allow_public_ingress     = optional(bool, false)
    allow_public_admin_ports = optional(bool, false)
  })

  # no `default` here because `name` and `vpc_id` are required

  # The atom enforces the full security contract via lifecycle preconditions and
  # validations; these component-level validations mirror the most important
  # ones so a misconfiguration fails fast at the component API boundary with a
  # clear, testable surface (var.config). PCI DSS Req 1.

  # Every rule must carry an explicit allow/deny action (no implicit allow).
  validation {
    condition = alltrue([
      for r in concat(var.config.ingress_rules, var.config.egress_rules) :
      contains(["allow", "deny"], r.rule_action)
    ])
    error_message = "Every rule's rule_action must be exactly \"allow\" or \"deny\"."
  }

  # Reject an ingress ALLOW rule open to the whole internet on an admin port
  # (22/SSH, 3389/RDP) unless config.allow_public_admin_ports is set.
  validation {
    condition = var.config.allow_public_admin_ports || length([
      for r in var.config.ingress_rules : r
      if r.rule_action == "allow"
      && contains(["0.0.0.0/0", "::/0"], coalesce(r.cidr_block, r.ipv6_cidr_block, "none"))
      && (
        contains(["-1", "0"], r.protocol) || r.from_port == null || r.to_port == null
        || anytrue([for p in [22, 3389] : r.from_port <= p && r.to_port >= p])
      )
    ]) == 0
    error_message = "An admin port (22/SSH or 3389/RDP) is opened to 0.0.0.0/0 or ::/0 without config.allow_public_admin_ports=true. File a PCI exception (security@emag.ro) and set the flag."
  }

  # Reject any ingress ALLOW rule open to the whole internet unless
  # config.allow_public_ingress is set.
  validation {
    condition = var.config.allow_public_ingress || length([
      for r in var.config.ingress_rules : r
      if r.rule_action == "allow"
      && contains(["0.0.0.0/0", "::/0"], coalesce(r.cidr_block, r.ipv6_cidr_block, "none"))
    ]) == 0
    error_message = "An ingress ALLOW rule is open to 0.0.0.0/0 or ::/0 without config.allow_public_ingress=true. File a PCI exception (security@emag.ro) and set the flag."
  }
}
