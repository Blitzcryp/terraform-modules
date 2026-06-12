variable "config" {
  description = <<-EOT
    Configuration for the secure-network component. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields: flow logs are ON by default and subnets are private by default.
    Required fields (name, cidr_block, subnets) have no default, so config
    cannot be omitted. Insecure choices require flipping an explicit `allow_*`
    escape hatch.
  EOT

  type = object({
    name       = string # required — no default
    cidr_block = string # required — no default

    # One object per subnet. Subnets are PRIVATE by default (public=false);
    # making a subnet public is an intentional, auditable choice.
    subnets = list(object({
      name              = string
      cidr_block        = string
      availability_zone = string
      public            = optional(bool, false)
    }))

    # --- Routing (additive) -----------------------------------------------
    # Internet gateway: null = auto (created iff any subnet is public). Set
    # true/false to force on/off.
    enable_internet_gateway = optional(bool)

    # NAT gateway strategy for private-subnet egress:
    #   "none"   = no NAT (private subnets get no default route)
    #   "single" = one NAT in the first public subnet (cheaper, single-AZ)
    #   "per_az" = one NAT per AZ that has a public subnet (HA, per-AZ private
    #              route tables)
    nat_gateway_mode = optional(string, "single")

    # --- Secure-by-default controls (PCI DSS Req 10 logging) ---
    enable_flow_logs           = optional(bool, true)  # PCI DSS Req 10
    flow_log_retention_in_days = optional(number, 365) # >= 1 year audit retention

    # Bring-your-own flow-log sink. When BOTH are provided, the component wires
    # them into the VPC and does NOT self-provision kms/log-group/iam-role
    # (e.g. inject a central log group + role from the audit-logging component).
    byo_flow_log_destination_arn = optional(string)
    byo_flow_log_role_arn        = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Forwarded to the vpc atom: permits enable_flow_logs=false.
    allow_flow_logs_disabled = optional(bool, false)
  })

  # no `default` here because name, cidr_block and subnets are required

  validation {
    condition     = can(cidrhost(var.config.cidr_block, 0))
    error_message = "config.cidr_block must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = length(var.config.subnets) > 0
    error_message = "config.subnets must contain at least one subnet."
  }

  validation {
    condition     = length(distinct([for s in var.config.subnets : s.name])) == length(var.config.subnets)
    error_message = "config.subnets[*].name must be unique."
  }

  validation {
    condition     = alltrue([for s in var.config.subnets : can(cidrhost(s.cidr_block, 0))])
    error_message = "Each config.subnets[*].cidr_block must be a valid IPv4 CIDR (e.g. 10.0.1.0/24)."
  }

  validation {
    condition = (
      (var.config.byo_flow_log_destination_arn == null) == (var.config.byo_flow_log_role_arn == null)
    )
    error_message = "config.byo_flow_log_destination_arn and config.byo_flow_log_role_arn must be provided together (both or neither)."
  }

  validation {
    condition     = contains(["none", "single", "per_az"], var.config.nat_gateway_mode)
    error_message = "config.nat_gateway_mode must be 'none', 'single', or 'per_az'."
  }

  # A NAT gateway needs a public subnet to host it and an internet gateway for
  # upstream egress. NAT is only ACTUALLY provisioned when a public subnet
  # exists (a private-only network silently provisions no NAT — same as
  # 'none'), so the only thing we must forbid is requesting NAT while
  # explicitly disabling the internet gateway, which would be unroutable.
  validation {
    condition = (
      var.config.nat_gateway_mode == "none" ||
      length([for s in var.config.subnets : s if s.public]) == 0 ||
      var.config.enable_internet_gateway != false
    )
    error_message = "config.nat_gateway_mode='single'|'per_az' with a public subnet requires config.enable_internet_gateway not set to false (NAT egress needs an internet gateway)."
  }
}
