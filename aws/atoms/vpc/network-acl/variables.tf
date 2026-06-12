variable "config" {
  description = <<-EOT
    Configuration for the network ACL. All inputs live on this single object.
    `vpc_id` is required (the caller must decide it). A network ACL is stateless
    and DEFAULT-DENY: traffic is dropped unless an explicit numbered rule allows
    it, in BOTH directions (return traffic needs its own rule — typically the
    ephemeral port range). PCI-DSS-compliant defaults are baked into the
    optional() fields: no rules at all (deny everything) until you add them, and
    insecure openings require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    vpc_id = string                 # required — the caller must decide this
    name   = optional(string, null) # used only for the Name tag

    # Subnet associations. A subnet may be associated with at most one NACL;
    # associating it here moves it off the VPC's default NACL.
    subnet_ids = optional(list(string), [])

    # --- Rules ----------------------------------------------------------
    #
    # NACL rules are numbered (evaluated low→high, first match wins) and each
    # carries an explicit rule_action ("allow" or "deny") — there is no implicit
    # allow. Each rule targets ONE source/destination (an IPv4 OR IPv6 CIDR).
    # tcp/udp require from_port+to_port; icmp uses icmp_type+icmp_code; "-1"
    # (all protocols) needs neither.
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

    # --- Escape hatches (insecure choices must be explicit & auditable) -
    # Permit an ALLOW rule whose source is the whole internet (0.0.0.0/0 or ::/0).
    allow_public_ingress = optional(bool, false)
    # Permit an ALLOW rule that exposes an admin port (22/SSH, 3389/RDP) to the
    # whole internet.
    allow_public_admin_ports = optional(bool, false)
  })

  # no `default` here because `vpc_id` is required

  # Every rule must carry an explicit allow/deny action (PCI DSS Req 1: no
  # implicit allow — each opening is deliberate and documented by its action).
  validation {
    condition = alltrue([
      for r in concat(var.config.ingress_rules, var.config.egress_rules) :
      contains(["allow", "deny"], r.rule_action)
    ])
    error_message = "Every rule's rule_action must be exactly \"allow\" or \"deny\"."
  }

  # Each rule targets EXACTLY ONE of cidr_block / ipv6_cidr_block.
  validation {
    condition = alltrue([
      for r in concat(var.config.ingress_rules, var.config.egress_rules) :
      length(compact([r.cidr_block, r.ipv6_cidr_block])) == 1
    ])
    error_message = "Every rule must set EXACTLY ONE of cidr_block or ipv6_cidr_block."
  }

  # tcp/udp rules require an explicit port range so the opening is bounded.
  validation {
    condition = alltrue([
      for r in concat(var.config.ingress_rules, var.config.egress_rules) :
      (r.from_port != null && r.to_port != null) if contains(["tcp", "udp", "6", "17"], r.protocol)
    ])
    error_message = "tcp/udp rules must set both from_port and to_port (PCI DSS Req 1: openings must be bounded)."
  }

  # Rule numbers must be unique within each direction (AWS rejects duplicates,
  # but failing fast at plan time gives a clearer message).
  validation {
    condition     = length(distinct([for r in var.config.ingress_rules : r.rule_number])) == length(var.config.ingress_rules)
    error_message = "config.ingress_rules rule_number values must be unique."
  }

  validation {
    condition     = length(distinct([for r in var.config.egress_rules : r.rule_number])) == length(var.config.egress_rules)
    error_message = "config.egress_rules rule_number values must be unique."
  }
}
