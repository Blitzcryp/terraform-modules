variable "config" {
  description = <<-EOT
    Configuration for the CloudFront Origin Access Control (OAC). All inputs live
    on this single object. An OAC lets CloudFront sign origin requests with SigV4
    so a private S3 origin can be locked down to CloudFront only (no public
    bucket access) — the modern replacement for the legacy Origin Access Identity.
    Secure-by-default values (SigV4 signing, always sign) are baked into the
    optional() fields, so passing only the required `name` yields a compliant OAC.
  EOT

  type = object({
    name        = string           # required — unique OAC name
    description = optional(string) # null = provider default

    # --- Secure-by-default signing (locks the origin to CloudFront) ---
    origin_access_control_origin_type = optional(string, "s3")
    signing_behavior                  = optional(string, "always")
    signing_protocol                  = optional(string, "sigv4")
  })

  # no `default` here because `name` is required

  validation {
    condition     = contains(["s3", "mediastore", "lambda", "mediapackagev2"], var.config.origin_access_control_origin_type)
    error_message = "config.origin_access_control_origin_type must be one of: s3, mediastore, lambda, mediapackagev2."
  }

  validation {
    condition     = contains(["always", "never", "no-override"], var.config.signing_behavior)
    error_message = "config.signing_behavior must be one of: always, never, no-override."
  }

  validation {
    condition     = var.config.signing_protocol == "sigv4"
    error_message = "config.signing_protocol must be sigv4 (the only protocol CloudFront OAC supports)."
  }
}
