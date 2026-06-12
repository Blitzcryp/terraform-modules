variable "config" {
  description = <<-EOT
    Configuration for the EventBridge rule atom (aws_cloudwatch_event_rule).
    All inputs live on this single object. A rule matches events either by an
    event pattern OR a schedule expression — exactly one must be supplied. The
    rule defaults to ENABLED so it starts routing immediately.
  EOT

  type = object({
    name        = string           # required — no default
    description = optional(string) # null = no description

    # Exactly one of these two must be set (validated below).
    event_pattern       = optional(string) # JSON string selecting matching events
    schedule_expression = optional(string) # rate(...) / cron(...) expression

    # Operational state of the rule.
    state = optional(string, "ENABLED")

    # Bus the rule attaches to. null = the account default event bus.
    event_bus_name = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` here because `name` is required

  validation {
    condition     = length(var.config.name) > 0 && length(var.config.name) <= 64
    error_message = "config.name must be 1-64 characters."
  }

  # Exactly one of event_pattern / schedule_expression.
  validation {
    condition = (
      (var.config.event_pattern != null ? 1 : 0) +
      (var.config.schedule_expression != null ? 1 : 0)
    ) == 1
    error_message = "Exactly one of config.event_pattern or config.schedule_expression must be set."
  }

  validation {
    condition = contains(
      ["ENABLED", "DISABLED", "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"],
      var.config.state
    )
    error_message = "config.state must be ENABLED, DISABLED, or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS."
  }
}
