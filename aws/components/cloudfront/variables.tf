variable "config" {
  description = <<-EOT
    Configuration for the cloudfront component: a secure CloudFront distribution
    fronting EITHER a private S3 origin (locked down via an Origin Access Control)
    OR a custom origin (e.g. an ALB / public hostname). When logging is enabled and
    no BYO log bucket is supplied, the component also owns a dedicated S3 access-log
    bucket. All inputs live on this single object.

    PCI-DSS-compliant defaults are baked into the optional() fields, so supplying
    only `name` + exactly one origin yields a distribution that:
      - serves viewers over TLS 1.2+ (minimum_protocol_version = TLSv1.2_2021, PCI Req 4),
      - redirects all viewer requests to HTTPS,
      - fronts S3 origins via an OAC so the bucket needs no public access (PCI Req 1/7),
      - ships access logs to S3 (PCI Req 10).

    APPLY-TIME NOTES (read before apply):
      - acm_certificate_arn MUST be an ACM certificate in us-east-1 (CloudFront
        requires viewer certs in us-east-1 regardless of where anything else lives).
        It is REQUIRED whenever `aliases` is non-empty; without it the distribution
        serves only on its *.cloudfront.net domain using the default certificate.
      - web_acl_arn MUST reference a WAFv2 web ACL created with CLOUDFRONT scope in
        us-east-1 (or a WAF Classic web ACL id).
      - LOGGING CAVEAT: CloudFront standard (legacy) access logging delivers logs
        via the awslogsdelivery account and REQUIRES the target bucket to have ACLs
        enabled (Object Ownership = BucketOwnerPreferred) and the log-delivery
        grant. The s3-bucket atom defaults to BucketOwnerEnforced (ACLs disabled),
        which CloudFront standard logging does NOT support. The owned log bucket is
        therefore created with object_ownership = "BucketOwnerPreferred"; you must
        still grant the log-delivery ACL out of band, OR migrate to CloudFront v2
        (CloudWatch Logs / Firehose) logging. For a fully managed flow, supply your
        own ACL-enabled bucket domain via `log_bucket`.
  EOT

  type = object({
    name = string # required — base name for the distribution and its child resources

    # --- Origin (exactly one of the two must be set) ---
    # The S3 bucket REGIONAL domain name (e.g. my-bucket.s3.eu-central-1.amazonaws.com).
    s3_origin_domain_name = optional(string)
    # A custom origin hostname (e.g. an ALB DNS name or public API host).
    custom_origin_domain_name = optional(string)

    # --- DNS / TLS (PCI DSS Req 4) ---
    aliases = optional(list(string), [])
    # ACM cert ARN in us-east-1 — REQUIRED if aliases is non-empty.
    acm_certificate_arn = optional(string)

    # --- WAF (us-east-1, CLOUDFRONT scope) ---
    web_acl_arn = optional(string)

    # --- Behavior / distribution knobs ---
    default_root_object = optional(string, "index.html")
    price_class         = optional(string, "PriceClass_100")

    # --- Access logging (PCI DSS Req 10) ---
    enable_logging = optional(bool, true)
    # BYO log bucket DOMAIN NAME (e.g. my-logs.s3.amazonaws.com). When set, the
    # component does not create a bucket and assumes it is ACL-enabled with the
    # CloudFront log-delivery grant attached.
    log_bucket = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` here because `name` is required

  # Exactly one origin must be supplied (XOR).
  validation {
    condition     = (var.config.s3_origin_domain_name != null) != (var.config.custom_origin_domain_name != null)
    error_message = "Set exactly one of config.s3_origin_domain_name OR config.custom_origin_domain_name (not both, not neither)."
  }

  validation {
    condition     = length(var.config.aliases) == 0 || var.config.acm_certificate_arn != null
    error_message = "config.acm_certificate_arn (ACM cert in us-east-1) is REQUIRED when config.aliases is non-empty."
  }

  validation {
    condition     = var.config.acm_certificate_arn == null || can(regex("^arn:aws[a-zA-Z-]*:acm:us-east-1:", var.config.acm_certificate_arn))
    error_message = "config.acm_certificate_arn must be an ACM certificate ARN in us-east-1 (CloudFront requirement): arn:aws:acm:us-east-1:..."
  }
}
