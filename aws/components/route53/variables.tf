variable "config" {
  description = <<-EOT
    Configuration for the route53 component (a hosted zone with DNS query
    logging — PCI DSS Req 10). All inputs live on this single object. PCI
    compliant defaults are baked into the optional() fields, so the caller only
    has to supply the required `name`: a public zone gets a CloudWatch-Logs
    query-log destination encrypted with a CMK this component creates.

    For PUBLIC zones the query-log group MUST live in us-east-1 (an AWS
    requirement for Route53 query logging). For PRIVATE zones query logging is
    not supported by Route53, so it is skipped entirely. Insecure choices flow
    down to the underlying atoms via their `allow_*` escape hatches.
  EOT

  type = object({
    name         = string                     # required — the DNS zone name
    private_zone = optional(bool, false)      # private zones cannot query-log
    vpc_ids      = optional(list(string), []) # VPC associations (private zones)

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---
    # BYO CMK for query-log encryption. null = this component creates one.
    kms_key_arn        = optional(string)
    log_retention_days = optional(number, 365) # >= 1 year of DNS query logs

    tags = optional(map(string), {})
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

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
