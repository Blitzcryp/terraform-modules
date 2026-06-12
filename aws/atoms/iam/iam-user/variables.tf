variable "config" {
  description = <<-EOT
    Configuration for the IAM user atom. All inputs live on this single object.
    The caller must supply the required `name`. PCI-DSS-compliant defaults are
    baked into the optional() fields.

    SECURITY (PCI DSS Req 8): this atom creates ONLY the user identity (and an
    optional permissions boundary). It deliberately creates NO long-lived static
    access keys and NO console login profile/password. Long-lived credentials are
    discouraged — prefer IAM roles, SSO, or OIDC/Web Identity federation. If a
    credential is unavoidable it must be issued out-of-band (e.g. console, CLI,
    or a secrets manager) and NEVER committed to source control.
  EOT

  type = object({
    # name is REQUIRED: the friendly IAM user name. No safe default exists.
    name = string

    path                 = optional(string, "/")
    permissions_boundary = optional(string)      # cap the user's maximum effective permissions (PCI DSS Req 7)
    force_destroy        = optional(bool, false) # delete the user even if it has non-Terraform-managed attachments
    tags                 = optional(map(string), {})
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }
}
