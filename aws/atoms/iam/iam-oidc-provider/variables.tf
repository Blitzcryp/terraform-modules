variable "config" {
  description = <<-EOT
    Configuration for the IAM OIDC identity provider. All inputs live on this
    single object. The caller supplies the required `url` and `client_id_list`
    (audience). AWS manages thumbprints for IAM OIDC providers pointing at
    well-known IdPs, so `thumbprint_list` may be left empty.
  EOT

  type = object({
    # url is REQUIRED: the OIDC issuer URL (e.g.
    # https://token.actions.githubusercontent.com). No safe default.
    url = string
    # client_id_list is REQUIRED: the audience(s) (aud) accepted from the IdP.
    client_id_list = list(string)

    thumbprint_list = optional(list(string), [])
    tags            = optional(map(string), {})
  })

  # no `default` here because url and client_id_list are required

  validation {
    condition     = can(regex("^https://", var.config.url))
    error_message = "config.url must be an https:// OIDC issuer URL."
  }

  validation {
    condition     = length(var.config.client_id_list) > 0
    error_message = "config.client_id_list must contain at least one audience (client id)."
  }
}
