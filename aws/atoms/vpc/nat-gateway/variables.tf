variable "config" {
  description = <<-EOT
    Configuration for the NAT gateway. All inputs live on this single object.
    A public NAT gateway lives in a PUBLIC subnet and uses an Elastic IP
    allocation; both are inputs (this atom does not create the subnet or EIP).
    Required fields (subnet_id, allocation_id) have no default.
  EOT

  type = object({
    subnet_id         = string           # required — public subnet for the NAT
    allocation_id     = string           # required — EIP allocation id
    name              = optional(string) # null = no Name tag override
    connectivity_type = optional(string, "public")
    tags              = optional(map(string), {})
  })

  # no `default` here because subnet_id and allocation_id are required

  validation {
    condition     = contains(["public", "private"], var.config.connectivity_type)
    error_message = "config.connectivity_type must be 'public' or 'private'."
  }
}
