variable "config" {
  description = <<-EOT
    Configuration for the IAM instance profile. All inputs live on this single
    object. The caller supplies the required `name` and `role` (the IAM role
    name the instance profile wraps).
  EOT

  type = object({
    # name is REQUIRED: the instance profile's identity.
    name = string
    # role is REQUIRED: the name of the IAM role this profile grants to EC2.
    role = string

    path = optional(string, "/")
    tags = optional(map(string), {})
  })

  # no `default` here because name and role are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.role) > 0
    error_message = "config.role must be a non-empty IAM role name."
  }
}
