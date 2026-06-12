variable "config" {
  description = <<-EOT
    Configuration for the Cognito user pool domain atom. Associates a hosted-UI
    domain with a user pool. Pass `certificate_arn` to serve a custom domain
    over an ACM-issued certificate (TLS); omit it to use a Cognito-prefix domain.
    All inputs live on this single object.
  EOT

  type = object({
    domain       = string # required — no default
    user_pool_id = string # required — no default

    # --- Custom domain TLS certificate (ACM, us-east-1) ---
    certificate_arn = optional(string)

    # aws_cognito_user_pool_domain is NOT a taggable resource. `tags` is accepted
    # for interface uniformity across atoms but is intentionally not applied to
    # any resource here. Documented per CONVENTIONS §5.
    tags = optional(map(string), {})
  })
  # no `default` here because `domain` and `user_pool_id` are required

  validation {
    condition     = length(var.config.domain) > 0
    error_message = "config.domain must be a non-empty string."
  }
}
