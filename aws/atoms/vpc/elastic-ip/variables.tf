variable "config" {
  description = <<-EOT
    Configuration for the Elastic IP. All inputs live on this single object.
    Defaults to a VPC-domain address, which is the only sensible choice for
    modern VPC networking (e.g. attaching to a NAT gateway).
  EOT

  type = object({
    name   = optional(string)        # null = no Name tag override
    domain = optional(string, "vpc") # "vpc" for VPC-scoped EIPs
    tags   = optional(map(string), {})
  })

  default = {}

  validation {
    condition     = contains(["vpc", "standard"], var.config.domain)
    error_message = "config.domain must be 'vpc' or 'standard'."
  }
}
