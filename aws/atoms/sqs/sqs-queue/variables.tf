variable "config" {
  description = <<-EOT
    Configuration for the SQS queue. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields: encryption
    at rest (Req 3) is ALWAYS on — a CMK when supplied, else SSE-SQS as fallback;
    a queue policy denying non-TLS access (Req 4) is attached by default; and a
    dead-letter queue is created by default. Disabling encryption entirely
    requires flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name       = string                # required — no default
    fifo_queue = optional(bool, false) # FIFO queues require a '.fifo' suffix on the name

    # --- Secure-by-default controls ---
    # PCI DSS Req 3: encryption at rest. A CMK ARN takes precedence; when null,
    # SSE-SQS (sqs_managed_sse_enabled) is used so encryption is NEVER off.
    kms_key_arn = optional(string)

    message_retention_seconds = optional(number, 345600) # 4 days

    # Dead-letter queue (operational resilience). On by default.
    enable_dlq        = optional(bool, true)
    max_receive_count = optional(number, 5)

    # PCI DSS Req 4: a default policy denies any access over a non-TLS transport.
    # Extra statements (list of IAM statement objects) may be appended here.
    additional_policy_statements = optional(any, [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # ESCAPE HATCH: disable BOTH KMS and SSE-SQS, leaving the queue unencrypted.
    # Requires a documented PCI exception (security@emag.ro).
    allow_unencrypted = optional(bool, false)
  })

  # no `default` here because `name` is required

  validation {
    condition     = length(var.config.name) > 0 && length(var.config.name) <= 80
    error_message = "config.name must be 1-80 characters."
  }

  validation {
    condition     = !var.config.fifo_queue || endswith(var.config.name, ".fifo")
    error_message = "config.name must end with '.fifo' when config.fifo_queue = true."
  }

  validation {
    condition     = var.config.message_retention_seconds >= 60 && var.config.message_retention_seconds <= 1209600
    error_message = "config.message_retention_seconds must be between 60 and 1209600 (14 days)."
  }

  validation {
    condition     = var.config.max_receive_count >= 1 && var.config.max_receive_count <= 1000
    error_message = "config.max_receive_count must be between 1 and 1000."
  }

  validation {
    condition     = can(tolist(var.config.additional_policy_statements))
    error_message = "config.additional_policy_statements must be a list of IAM policy statement objects."
  }
}
