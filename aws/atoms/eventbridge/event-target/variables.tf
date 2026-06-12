variable "config" {
  description = <<-EOT
    Configuration for the EventBridge target atom (aws_cloudwatch_event_target).
    All inputs live on this single object. A target binds an EventBridge rule to
    a destination ARN (SNS topic, Lambda, SQS queue, ...).

    NOTE on tags: aws_cloudwatch_event_target has NO tags argument. The `tags`
    field is accepted here only for uniformity with the rest of the library
    (every atom takes config.tags) and is intentionally NOT applied to any
    resource. It is therefore a no-op for this atom.
  EOT

  type = object({
    rule = string # required — name of the EventBridge rule this target attaches to
    arn  = string # required — ARN of the destination (SNS topic, Lambda, SQS, ...)

    target_id      = optional(string) # null = provider-generated unique id
    event_bus_name = optional(string) # must match the rule's bus; null = default bus
    role_arn       = optional(string) # IAM role EventBridge assumes (for some targets)

    # Supply at most one of input / input_path (validated below).
    input      = optional(string) # constant JSON text passed to the target
    input_path = optional(string) # JSONPath extracting part of the event

    # Accepted for uniformity only; NOT applied (resource has no tags). See above.
    tags = optional(map(string), {})
  })

  # no `default` here because `rule` and `arn` are required

  validation {
    condition     = length(var.config.rule) > 0 && length(var.config.rule) <= 64
    error_message = "config.rule must be 1-64 characters (the EventBridge rule name)."
  }

  validation {
    condition     = can(regex("^arn:aws", var.config.arn))
    error_message = "config.arn must be a valid AWS ARN for the target destination."
  }

  validation {
    condition     = !(var.config.input != null && var.config.input_path != null)
    error_message = "At most one of config.input or config.input_path may be set."
  }
}
