variable "config" {
  description = <<-EOT
    Configuration for the iam-user component (a single human/service IAM user,
    secure by default). All inputs live on this single object; the caller must
    supply the required `name`.

    SECURITY (PCI DSS Req 8): this component creates ONLY the user identity (plus
    an optional permissions boundary). It creates NO static access keys and NO
    console login password. Long-lived credentials are discouraged — prefer IAM
    roles, SSO, or OIDC/Web Identity federation; any credential must be issued
    out-of-band and never committed to source control.

    Group membership is NOT managed here: it is managed group-centrically by the
    iam-group component (which owns each group's full membership). MFA
    enforcement is an org/account-level control, not something this component
    fabricates — see the README.
  EOT

  type = object({
    # name is REQUIRED: the friendly IAM user name. No safe default exists.
    name = string

    path                 = optional(string, "/")
    permissions_boundary = optional(string) # cap the user's maximum effective permissions (PCI DSS Req 7)
    force_destroy        = optional(bool, false)
    tags                 = optional(map(string), {})
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }
}
