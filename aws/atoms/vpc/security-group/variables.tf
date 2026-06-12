variable "config" {
  description = <<-EOT
    Configuration for the security group. All inputs live on this single object.
    `name` and `vpc_id` are required (the caller must decide them). PCI-DSS-compliant
    defaults are baked into the optional() fields: no public ingress, no implicit
    allow-all egress. Insecure choices require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name        = string # required — the caller must decide this
    vpc_id      = string # required — the caller must decide this
    description = optional(string, "Managed by terraform (atoms/security-group)")

    # --- Rules ----------------------------------------------------------
    #
    # Each rule targets EXACTLY ONE source/destination: an IPv4 CIDR, an IPv6
    # CIDR, a referenced security group, or a managed prefix list. `description`
    # is REQUIRED on every rule so each opening is documented (PCI DSS Req 1.1.x).
    ingress_rules = optional(list(object({
      description                  = string
      ip_protocol                  = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      referenced_security_group_id = optional(string)
      prefix_list_id               = optional(string)
    })), [])

    egress_rules = optional(list(object({
      description                  = string
      ip_protocol                  = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      referenced_security_group_id = optional(string)
      prefix_list_id               = optional(string)
    })), [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) -
    allow_public_ingress     = optional(bool, false)
    allow_public_admin_ports = optional(bool, false)
  })

  # no `default` here because `name` and `vpc_id` are required

  validation {
    condition     = alltrue([for r in var.config.ingress_rules : trimspace(r.description) != ""])
    error_message = "Every config.ingress_rules entry must have a non-empty description (PCI DSS Req 1: rules must be documented)."
  }

  validation {
    condition = alltrue([
      for r in var.config.ingress_rules :
      length(compact([r.cidr_ipv4, r.cidr_ipv6, r.referenced_security_group_id, r.prefix_list_id])) == 1
    ])
    error_message = "Every config.ingress_rules entry must set EXACTLY ONE of cidr_ipv4, cidr_ipv6, referenced_security_group_id, or prefix_list_id."
  }

  validation {
    condition     = alltrue([for r in var.config.egress_rules : trimspace(r.description) != ""])
    error_message = "Every config.egress_rules entry must have a non-empty description (PCI DSS Req 1: rules must be documented)."
  }

  validation {
    condition = alltrue([
      for r in var.config.egress_rules :
      length(compact([r.cidr_ipv4, r.cidr_ipv6, r.referenced_security_group_id, r.prefix_list_id])) == 1
    ])
    error_message = "Every config.egress_rules entry must set EXACTLY ONE of cidr_ipv4, cidr_ipv6, referenced_security_group_id, or prefix_list_id."
  }
}
