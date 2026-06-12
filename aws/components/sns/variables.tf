variable "config" {
  description = <<-EOT
    Configuration for the sns component (an encrypted SNS topic). All inputs live
    on this single object. PCI-DSS-compliant defaults are baked into the
    optional() fields, so passing only the required `name` yields a topic that is
    encrypted at rest with a dedicated CMK and carries a policy denying non-TLS
    publish.

    This component composes atoms via module blocks: a kms-key atom (unless a
    `kms_key_arn` is supplied), the sns-topic atom, and one sns-subscription atom
    per entry in `subscriptions`.
  EOT

  type = object({
    # --- Required: the caller must decide the topic name. ---
    name = string

    # --- Encryption (PCI DSS Req 3) ---
    # BYOK: when set, the supplied CMK is used and no kms-key atom is created.
    # When null, a dedicated kms-key atom is created for this topic.
    kms_key_arn = optional(string)

    # FIFO topics require a '.fifo' suffix on the name (validated by the atom).
    fifo_topic = optional(bool, false)

    # --- Topic policy (PCI DSS Req 4) ---
    # The TLS-deny statement is contributed by the sns-topic atom; extra
    # statements (list of IAM statement objects) are appended here.
    additional_policy_statements = optional(any, [])

    # --- Subscriptions ---
    # Each entry creates one sns-subscription atom bound to this topic.
    subscriptions = optional(list(object({
      protocol = string
      endpoint = string
    })), [])

    # --- Tagging ---
    tags = optional(map(string), {})
  })

  # no `default` here because `name` is required

  validation {
    condition     = length(var.config.name) > 0 && length(var.config.name) <= 256
    error_message = "config.name must be 1-256 characters."
  }

  validation {
    condition     = !var.config.fifo_topic || endswith(var.config.name, ".fifo")
    error_message = "config.name must end with '.fifo' when config.fifo_topic = true."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = can(tolist(var.config.additional_policy_statements))
    error_message = "config.additional_policy_statements must be a list of IAM policy statement objects."
  }
}
