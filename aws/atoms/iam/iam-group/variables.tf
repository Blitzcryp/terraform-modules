variable "config" {
  description = <<-EOT
    Configuration for the IAM group atom. All inputs live on this single object.
    The caller must supply the required `name`. PCI-DSS-compliant defaults are
    baked into the optional() fields.

    A group is the recommended way to grant permissions to human users (PCI DSS
    Req 7 least privilege): attach policies to the group and add users to it,
    rather than attaching policies directly to individual users.
  EOT

  type = object({
    # name is REQUIRED: the friendly IAM group name. No safe default exists.
    name = string

    path = optional(string, "/")
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }
}
