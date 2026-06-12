variable "config" {
  description = <<-EOT
    Configuration for the sqs component (an encrypted SQS queue with a DLQ). All
    inputs live on this single object. PCI-DSS-compliant defaults are baked into
    the optional() fields, so passing only the required `name` yields a queue
    encrypted at rest with a dedicated CMK, a dead-letter queue, and a policy
    denying non-TLS access.

    This component composes atoms via module blocks: a kms-key atom (unless a
    `kms_key_arn` is supplied) and the sqs-queue atom (which owns its DLQ).
  EOT

  type = object({
    # --- Required: the caller must decide the queue name. ---
    name = string

    # --- Encryption (PCI DSS Req 3) ---
    # BYOK: when set, the supplied CMK is used and no kms-key atom is created.
    # When null, a dedicated kms-key atom is created for this queue.
    kms_key_arn = optional(string)

    # FIFO queues require a '.fifo' suffix on the name (validated by the atom).
    fifo_queue = optional(bool, false)

    # --- Dead-letter queue (operational resilience). On by default. ---
    enable_dlq        = optional(bool, true)
    max_receive_count = optional(number, 5)

    # --- Retention ---
    message_retention_seconds = optional(number, 345600) # 4 days

    # --- Queue policy (PCI DSS Req 4) ---
    # The TLS-deny statement is contributed by the sqs-queue atom; extra
    # statements (list of IAM statement objects) are appended here.
    additional_policy_statements = optional(any, [])

    # --- Tagging ---
    tags = optional(map(string), {})
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
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
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
