variable "config" {
  description = <<-EOT
    Configuration for the API Gateway v2 stage. All inputs live on this single
    object. PCI-compliant defaults are baked into the optional() fields:

      - Access logging is ON (PCI DSS Req 10): a CloudWatch log group ARN must be
        supplied via access_log_destination_arn. Running with no destination
        requires flipping the explicit allow_no_access_logs escape hatch.
      - Default-route throttling is ON (burst + rate limits) to protect the
        backend from abuse.
  EOT

  type = object({
    # api_id is REQUIRED: this stage belongs to a specific API. No default.
    api_id = string

    name        = optional(string, "$default")
    auto_deploy = optional(bool, true)

    # --- Access logging (PCI DSS Req 10) ---
    # ARN of the CloudWatch log group that receives access logs. When null, the
    # stage is created with NO access logging, which requires allow_no_access_logs.
    access_log_destination_arn = optional(string)

    # --- Throttling (protect the backend) ---
    throttling_burst_limit = optional(number, 5000)
    throttling_rate_limit  = optional(number, 10000)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_no_access_logs = optional(bool, false)
  })

  # no `default` here because api_id is required

  validation {
    condition     = var.config.throttling_burst_limit >= 0
    error_message = "config.throttling_burst_limit must be >= 0."
  }

  validation {
    condition     = var.config.throttling_rate_limit >= 0
    error_message = "config.throttling_rate_limit must be >= 0."
  }
}
