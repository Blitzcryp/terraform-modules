variable "config" {
  description = <<-EOT
    Configuration for the route table. All inputs live on this single object.
    This atom owns the route table plus its tightly-coupled routes and subnet
    associations (meaningless on their own). Each route must specify exactly one
    target (gateway_id, nat_gateway_id, or vpc_endpoint_id). Required field
    (vpc_id) has no default, so config cannot be omitted.
  EOT

  type = object({
    vpc_id = string           # required — no default
    name   = optional(string) # null = no Name tag override

    # Routes added to the table. Each must set exactly one target.
    routes = optional(list(object({
      cidr_block      = string
      gateway_id      = optional(string)
      nat_gateway_id  = optional(string)
      vpc_endpoint_id = optional(string)
    })), [])

    # Subnets associated to this route table.
    subnet_ids = optional(list(string), [])

    tags = optional(map(string), {})
  })

  # no `default` here because vpc_id is required

  validation {
    condition = alltrue([
      for r in var.config.routes :
      length([for t in [r.gateway_id, r.nat_gateway_id, r.vpc_endpoint_id] : t if t != null]) == 1
    ])
    error_message = "Each config.routes[*] must specify exactly one target (gateway_id, nat_gateway_id, or vpc_endpoint_id)."
  }

  validation {
    condition     = alltrue([for r in var.config.routes : can(cidrhost(r.cidr_block, 0))])
    error_message = "Each config.routes[*].cidr_block must be a valid IPv4 CIDR (e.g. 0.0.0.0/0)."
  }
}
