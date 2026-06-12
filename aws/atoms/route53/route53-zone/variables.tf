variable "config" {
  description = <<-EOT
    Configuration for the Route53 hosted zone. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    passing only the required `name` yields a compliant zone (DNS query logging
    enabled for public zones — PCI DSS Req 10). Insecure choices require flipping
    an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name          = string # required — the DNS zone name
    comment       = optional(string, "Managed by terraform (atoms/route53-zone)")
    private_zone  = optional(bool, false)      # private zones cannot query-log
    vpc_ids       = optional(list(string), []) # VPC associations (private zones)
    force_destroy = optional(bool, false)      # delete even with records present

    # --- Secure-by-default controls (PCI DSS Req 10: log all access) ---
    # CloudWatch Logs group ARN for DNS query logging. For PUBLIC zones this
    # group MUST live in us-east-1. null = no destination configured.
    query_log_destination_arn = optional(string)
    tags                      = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit a public zone with no query logging configured.
    allow_query_logging_disabled = optional(bool, false)
  })
  # `name` is required, so no `default = {}`.

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty DNS zone name."
  }

  validation {
    condition     = var.config.private_zone == false || length(var.config.vpc_ids) > 0
    error_message = "config.vpc_ids must contain at least one VPC id when config.private_zone=true."
  }
}
