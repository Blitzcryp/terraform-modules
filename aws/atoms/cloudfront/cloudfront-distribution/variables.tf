variable "config" {
  description = <<-EOT
    Configuration for the CloudFront distribution. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so a
    caller supplying only the required origins + default_cache_behavior gets a
    distribution that:
      - serves viewers over TLS 1.2+ (minimum_protocol_version = TLSv1.2_2021, PCI Req 4),
      - redirects all viewer requests to HTTPS (viewer_protocol_policy = redirect-to-https),
      - ships access logs to S3 when log_bucket is set (PCI Req 10).
    Insecure choices (weak TLS, allow-all viewer protocol) require flipping an
    explicit `allow_*` escape hatch.

    APPLY-TIME NOTES:
      - acm_certificate_arn MUST be an ACM cert in us-east-1 (CloudFront requires
        certs in us-east-1 regardless of distribution region). When null, the
        distribution uses the default *.cloudfront.net certificate and aliases
        must be empty.
      - web_acl_id MUST reference a WAFv2 web ACL ARN created with CLOUDFRONT
        scope in us-east-1 (or a WAF Classic web ACL id).
  EOT

  type = object({
    enabled             = optional(bool, true)
    comment             = optional(string)
    aliases             = optional(list(string), [])
    default_root_object = optional(string, "index.html")
    price_class         = optional(string, "PriceClass_100")
    web_acl_id          = optional(string) # WAFv2 ARN (CLOUDFRONT scope, us-east-1) or WAF Classic id

    # --- TLS / viewer certificate (PCI DSS Req 4) ---
    # When acm_certificate_arn is null the default CloudFront cert is used.
    acm_certificate_arn      = optional(string)
    minimum_protocol_version = optional(string, "TLSv1.2_2021")
    ssl_support_method       = optional(string, "sni-only")

    # --- Origins (required) ---
    origins = list(object({
      domain_name              = string
      origin_id                = string
      origin_access_control_id = optional(string) # set for private S3 origins (OAC)
      origin_path              = optional(string)
      s3_origin_config = optional(object({
        origin_access_identity = optional(string, "")
      }))
      custom_origin_config = optional(object({
        http_port                = optional(number, 80)
        https_port               = optional(number, 443)
        origin_protocol_policy   = optional(string, "https-only")
        origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
        origin_read_timeout      = optional(number)
        origin_keepalive_timeout = optional(number)
      }))
    }))

    # --- Default cache behavior (required) ---
    default_cache_behavior = object({
      target_origin_id       = string
      allowed_methods        = optional(list(string), ["GET", "HEAD"])
      cached_methods         = optional(list(string), ["GET", "HEAD"])
      viewer_protocol_policy = optional(string, "redirect-to-https")
      compress               = optional(bool, true)
      cache_policy_id        = optional(string) # use this OR forwarded_values
      forwarded_values = optional(object({
        query_string = optional(bool, false)
        headers      = optional(list(string), [])
        cookies = optional(object({
          forward = optional(string, "none")
        }), {})
      }))
    })

    # --- Ordered cache behaviors (optional) ---
    ordered_cache_behaviors = optional(list(object({
      path_pattern           = string
      target_origin_id       = string
      allowed_methods        = optional(list(string), ["GET", "HEAD"])
      cached_methods         = optional(list(string), ["GET", "HEAD"])
      viewer_protocol_policy = optional(string, "redirect-to-https")
      compress               = optional(bool, true)
      cache_policy_id        = optional(string)
      forwarded_values = optional(object({
        query_string = optional(bool, false)
        headers      = optional(list(string), [])
        cookies = optional(object({
          forward = optional(string, "none")
        }), {})
      }))
    })), [])

    # --- Access logging (PCI DSS Req 10) ---
    # When log_bucket is set, a logging_config is emitted. The bucket must be the
    # S3 bucket *domain name* (e.g. my-logs.s3.amazonaws.com) and must have ACLs
    # enabled / log-delivery permission (see component for the caveat).
    log_bucket          = optional(string)
    log_prefix          = optional(string)
    log_include_cookies = optional(bool, false)

    # --- Geo restriction ---
    geo_restriction = optional(object({
      restriction_type = optional(string, "none")
      locations        = optional(list(string), [])
    }), { restriction_type = "none" })

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit a minimum_protocol_version weaker than TLSv1.2_2021.
    allow_weak_tls = optional(bool, false)
    # Permit viewer_protocol_policy = "allow-all" (serves plain HTTP).
    allow_insecure_viewer = optional(bool, false)
  })

  # no `default` here because origins/default_cache_behavior are required

  validation {
    condition     = length(var.config.origins) > 0
    error_message = "config.origins must contain at least one origin."
  }

  validation {
    condition     = var.config.acm_certificate_arn == null || can(regex("^arn:aws[a-zA-Z-]*:acm:us-east-1:", var.config.acm_certificate_arn))
    error_message = "config.acm_certificate_arn, when set, must be an ACM certificate ARN in us-east-1 (CloudFront requirement): arn:aws:acm:us-east-1:..."
  }

  # Custom alternate domain names require a real ACM cert (the default
  # *.cloudfront.net cert cannot serve custom aliases).
  validation {
    condition     = length(var.config.aliases) == 0 || var.config.acm_certificate_arn != null
    error_message = "config.aliases require config.acm_certificate_arn (us-east-1). The default CloudFront certificate only serves *.cloudfront.net."
  }

  # PCI DSS Req 4: viewer protocol policy must not be allow-all unless the caller
  # explicitly opts in via the escape hatch.
  validation {
    condition     = var.config.default_cache_behavior.viewer_protocol_policy != "allow-all" || var.config.allow_insecure_viewer
    error_message = "default_cache_behavior.viewer_protocol_policy = 'allow-all' serves plain HTTP. Set config.allow_insecure_viewer=true with a documented PCI exception (security@emag.ro)."
  }

  validation {
    condition = alltrue([
      for b in var.config.ordered_cache_behaviors :
      b.viewer_protocol_policy != "allow-all" || var.config.allow_insecure_viewer
    ])
    error_message = "An ordered_cache_behavior uses viewer_protocol_policy = 'allow-all'. Set config.allow_insecure_viewer=true with a documented PCI exception."
  }

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.config.geo_restriction.restriction_type)
    error_message = "config.geo_restriction.restriction_type must be none, whitelist, or blacklist."
  }
}
