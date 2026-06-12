variable "config" {
  description = <<-EOT
    Configuration for the WAFv2 Web ACL. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so passing
    only the required fields yields a compliant ACL: managed rule groups for the
    OWASP-style common set, known-bad inputs and SQLi are enabled, request
    metrics/sampling are on, and logging is required. Insecure choices require
    flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name        = string                                                         # required
    description = optional(string, "Managed by terraform (atoms/wafv2-web-acl)") # secure default

    # --- Core controls (PCI DSS Req 6.4.x: protect public-facing web apps) ---
    scope          = optional(string, "REGIONAL") # REGIONAL | CLOUDFRONT
    default_action = optional(string, "allow")    # allow | block

    # AWS-managed rule groups, ON by default. Override the list to extend/replace.
    managed_rule_groups = optional(list(object({
      name              = string
      vendor_name       = optional(string, "AWS")
      priority          = number
      override_to_count = optional(bool, false) # count-only (test) instead of enforcing
      })), [
      { name = "AWSManagedRulesCommonRuleSet", priority = 0 },
      { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 1 },
      { name = "AWSManagedRulesSQLiRuleSet", priority = 2 },
    ])

    # Optional rate-based rule. null = no rate limit. When set, must be 100..2e9.
    rate_limit = optional(number)

    # --- Logging (PCI DSS Req 10: log all access to the in-scope web tier) ---
    # ARN of a CloudWatch Logs log group (name must start with aws-waf-logs-),
    # Kinesis Firehose, or S3 bucket. Required unless allow_logging_disabled=true.
    log_destination_arn = optional(string)

    # Passthrough for caller-authored custom rules (already-formed rule objects).
    custom_rules = optional(list(any), [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_logging_disabled = optional(bool, false)
  })
  # no `default` here because `name` is required

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.config.scope)
    error_message = "config.scope must be REGIONAL or CLOUDFRONT."
  }

  validation {
    condition     = contains(["allow", "block"], var.config.default_action)
    error_message = "config.default_action must be allow or block."
  }

  validation {
    condition     = var.config.rate_limit == null || (try(var.config.rate_limit, 0) >= 100 && try(var.config.rate_limit, 0) <= 2000000000)
    error_message = "config.rate_limit must be between 100 and 2000000000 when set."
  }
}
