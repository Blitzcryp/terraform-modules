variable "config" {
  description = <<-EOT
    Configuration for the findings-notification component: routes AWS security
    findings to an encrypted SNS topic via EventBridge. Closes the
    Inspector/GuardDuty/Security Hub -> SNS gap.

    All inputs live on this single object. PCI-compliant defaults are baked into
    the optional() fields: passing only the required `name` creates a CMK
    (KMS-encrypted, rotation on), a KMS-encrypted SNS topic that denies non-TLS
    publish and allows EventBridge to publish, an EventBridge rule matching ALL
    supported finding sources, and a target wiring that rule to the topic.

    This component composes atoms via module blocks ONLY: kms/kms-key (unless a
    BYO `kms_key_arn` is supplied), sns/sns-topic, eventbridge/event-rule and
    eventbridge/event-target.
  EOT

  type = object({
    # --- Required: the caller must decide the base name. ---
    name = string

    # Which security service's findings to route. "all" routes Security Hub,
    # Inspector and GuardDuty findings. Build the event pattern accordingly.
    source = optional(string, "all")

    # BYO CMK for the SNS topic. null = this component creates one with a key
    # policy allowing EventBridge to use it (PCI DSS Req 3 encryption at rest).
    kms_key_arn = optional(string)

    # Escape hatch / advanced: a full event_pattern JSON string that OVERRIDES
    # the source-derived pattern. null = derive the pattern from `source`.
    additional_event_pattern = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` here because `name` is required

  validation {
    condition     = length(var.config.name) > 0 && length(var.config.name) <= 64
    error_message = "config.name must be 1-64 characters."
  }

  validation {
    condition     = contains(["securityhub", "inspector", "guardduty", "all"], var.config.source)
    error_message = "config.source must be one of securityhub, inspector, guardduty, all."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
