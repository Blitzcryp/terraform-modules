variable "config" {
  description = <<-EOT
    Configuration for a single CloudWatch metric alarm. All inputs live on this
    one object. This atom owns exactly one `aws_cloudwatch_metric_alarm`.

    Secure-by-default posture (PCI DSS Req 10.6 — alert on security events):
    `treat_missing_data` defaults to "notBreaching" so a quiet metric does not
    silently flap, and the caller must supply `alarm_actions` (an SNS topic) for
    the alarm to actually notify. Required inputs (alarm_name, comparison_operator,
    evaluation_periods) carry no defaults.
  EOT

  type = object({
    # --- Required: the caller must decide these. No defaults. ---
    alarm_name          = string
    comparison_operator = string
    evaluation_periods  = number

    # --- The metric being watched. Optional so math/expression alarms remain
    #     possible, but for a standard single-metric alarm all four are needed. ---
    metric_name = optional(string)
    namespace   = optional(string)
    period      = optional(number, 300)
    statistic   = optional(string, "Sum")
    threshold   = optional(number, 1)

    # --- Notification wiring (SNS topic ARNs). ---
    alarm_actions = optional(list(string), [])
    ok_actions    = optional(list(string), [])

    alarm_description   = optional(string)
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "notBreaching")
    datapoints_to_alarm = optional(number)

    tags = optional(map(string), {})
  })

  # no `default` here because alarm_name/comparison_operator/evaluation_periods are required

  validation {
    condition = contains([
      "GreaterThanOrEqualToThreshold",
      "GreaterThanThreshold",
      "LessThanThreshold",
      "LessThanOrEqualToThreshold",
      "LessThanLowerOrGreaterThanUpperThreshold",
      "LessThanLowerThreshold",
      "GreaterThanUpperThreshold",
    ], var.config.comparison_operator)
    error_message = "config.comparison_operator must be a valid CloudWatch comparison operator (e.g. GreaterThanOrEqualToThreshold)."
  }

  validation {
    condition     = var.config.evaluation_periods >= 1
    error_message = "config.evaluation_periods must be >= 1."
  }

  validation {
    condition = contains(
      ["missing", "ignore", "breaching", "notBreaching"],
      var.config.treat_missing_data
    )
    error_message = "config.treat_missing_data must be one of: missing, ignore, breaching, notBreaching."
  }

  validation {
    condition = var.config.statistic == null || contains(
      ["SampleCount", "Average", "Sum", "Minimum", "Maximum"],
      var.config.statistic
    )
    error_message = "config.statistic must be one of: SampleCount, Average, Sum, Minimum, Maximum."
  }
}
