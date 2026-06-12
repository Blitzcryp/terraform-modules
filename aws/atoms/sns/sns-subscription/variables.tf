variable "config" {
  description = <<-EOT
    Configuration for a single SNS topic subscription. All inputs live on this
    single object. Defaults favour the secure-by-default posture: raw message
    delivery is off and endpoints are NOT auto-confirmed by Terraform.

    This atom owns exactly one `aws_sns_topic_subscription`. The topic ARN it
    binds to is passed in by reference (a higher layer owns the topic).
  EOT

  type = object({
    topic_arn = string # required — the topic this subscription binds to
    protocol  = string # required — sqs | lambda | firehose | application | sms | email | email-json | http | https
    endpoint  = string # required — destination (format depends on protocol)

    # Operational knobs (kept conservative by default).
    raw_message_delivery   = optional(bool, false)
    endpoint_auto_confirms = optional(bool, false)
    filter_policy          = optional(string) # null = no filter

    tags = optional(map(string), {})
  })

  # no `default` here because topic_arn/protocol/endpoint are required

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:sns:", var.config.topic_arn))
    error_message = "config.topic_arn must be a valid SNS topic ARN (arn:aws:sns:...)."
  }

  validation {
    condition     = contains(["sqs", "lambda", "firehose", "application", "sms", "email", "email-json", "http", "https"], var.config.protocol)
    error_message = "config.protocol must be one of: sqs, lambda, firehose, application, sms, email, email-json, http, https."
  }

  validation {
    condition     = length(var.config.endpoint) > 0
    error_message = "config.endpoint must be a non-empty destination string."
  }
}
