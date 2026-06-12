variable "config" {
  description = <<-EOT
    Configuration for the waf component: a WAFv2 Web ACL with request logging to a
    dedicated, KMS-encrypted CloudWatch log group, and optional associations to
    regional resources (ALBs, API Gateway stages, ...). All inputs live on this
    single object.

    PCI-DSS-compliant defaults are baked into the optional() fields, so supplying
    only the required `name` yields a compliant ACL that:
      - enables the three AWS baseline managed rule groups (Common, KnownBadInputs,
        SQLi) via the wafv2-web-acl atom default,
      - ships request logs to a KMS-encrypted CloudWatch log group with >= 1 year
        retention (PCI DSS Req 10),
      - owns a CMK whose policy authorises the regional CloudWatch Logs service.
    Insecure choices require flipping escape hatches on the underlying atoms.
  EOT

  type = object({
    name  = string                       # required — base name for the ACL, log group, and CMK alias
    scope = optional(string, "REGIONAL") # REGIONAL (ALB/APIGW) | CLOUDFRONT

    # AWS-managed rule groups. null => the wafv2-web-acl atom's secure default
    # (the three AWS baseline groups). Override to extend/replace.
    managed_rule_groups = optional(list(object({
      name              = string
      vendor_name       = optional(string, "AWS")
      priority          = number
      override_to_count = optional(bool, false)
    })))

    # Optional rate-based rule (requests per 5-min per IP). null = no rate limit.
    rate_limit = optional(number)

    # Regional resource ARNs to protect. One association atom is created per ARN.
    # Only valid when scope = REGIONAL (CLOUDFRONT ACLs attach via the CDN).
    associate_resource_arns = optional(list(string), [])

    # --- Logging (PCI DSS Req 10) ----------------------------------------
    # BYO CMK ARN for the log group. null => the component creates a CMK whose
    # policy authorises the regional CloudWatch Logs service principal.
    kms_key_arn        = optional(string)
    log_retention_days = optional(number, 365) # >= 1 year of WAF request logs

    tags = optional(map(string), {})
  })

  # no `default` here because `name` is required

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.config.scope)
    error_message = "config.scope must be REGIONAL or CLOUDFRONT."
  }

  validation {
    condition     = var.config.rate_limit == null || (try(var.config.rate_limit, 0) >= 100 && try(var.config.rate_limit, 0) <= 2000000000)
    error_message = "config.rate_limit must be between 100 and 2000000000 when set."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  # CLOUDFRONT-scoped ACLs cannot be associated to regional resources via this atom.
  validation {
    condition     = var.config.scope == "REGIONAL" || length(var.config.associate_resource_arns) == 0
    error_message = "config.associate_resource_arns is only valid when config.scope = REGIONAL (CLOUDFRONT ACLs attach via the distribution)."
  }

  validation {
    condition     = alltrue([for a in var.config.associate_resource_arns : can(regex("^arn:aws[a-zA-Z-]*:", a))])
    error_message = "Every config.associate_resource_arns entry must be a valid AWS resource ARN (arn:aws:...)."
  }
}
