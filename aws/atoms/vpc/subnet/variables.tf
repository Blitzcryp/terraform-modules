variable "config" {
  description = <<-EOT
    Configuration for the subnet. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields. Required
    fields (name, vpc_id, cidr_block, availability_zone) have no default, so
    config cannot be omitted. Insecure choices require flipping an explicit
    `allow_*` escape hatch.
  EOT

  type = object({
    name              = string # required — no default
    vpc_id            = string # required — no default
    cidr_block        = string # required — no default
    availability_zone = string # required — no default

    # --- Secure-by-default controls (PCI DSS Req 1 — no auto public exposure) ---
    map_public_ip_on_launch = optional(bool, false)
    tags                    = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_auto_public_ip = optional(bool, false)
  })

  # no `default` here because name, vpc_id, cidr_block, availability_zone are required

  validation {
    condition     = can(cidrhost(var.config.cidr_block, 0))
    error_message = "config.cidr_block must be a valid IPv4 CIDR (e.g. 10.0.1.0/24)."
  }
}
