variable "config" {
  description = <<-EOT
    Configuration for a single CloudWatch Logs metric filter. All inputs live on
    this one object. This atom owns exactly one `aws_cloudwatch_log_metric_filter`.

    A metric filter extracts a numeric metric from log events matching `pattern`
    (typically the CloudTrail->CloudWatch Logs group). Pairing it with a
    cloudwatch-metric-alarm implements PCI DSS Req 10.6 (alert on security events).

    NOTE on tags: `aws_cloudwatch_log_metric_filter` is NOT a taggable resource.
    `tags` is accepted here only for interface uniformity with the rest of the
    library and is intentionally not applied to any resource.
  EOT

  type = object({
    # --- Required: the caller must decide these. No defaults. ---
    name           = string
    log_group_name = string
    pattern        = string
    metric_name    = string

    # --- The metric transformation. CISBenchmark namespace + value "1" matches
    #     the CIS AWS Foundations monitoring recipe (count of matching events). ---
    metric_namespace = optional(string, "CISBenchmark")
    metric_value     = optional(string, "1")
    default_value    = optional(number) # null = no value emitted on non-match

    # Accepted for interface uniformity only; NOT applied (resource is untaggable).
    tags = optional(map(string), {})
  })

  # no `default` here because name/log_group_name/pattern/metric_name are required

  validation {
    condition     = length(var.config.name) > 0 && length(var.config.name) <= 512
    error_message = "config.name must be 1-512 characters."
  }

  validation {
    condition     = length(var.config.pattern) <= 1024
    error_message = "config.pattern must be at most 1024 characters."
  }
}
