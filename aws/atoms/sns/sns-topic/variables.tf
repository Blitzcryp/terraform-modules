variable "config" {
  description = <<-EOT
    Configuration for the SNS topic. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields: encryption
    at rest (Req 3) is on whenever a CMK is supplied, and a topic policy denying
    non-TLS publish (Req 4) is attached by default. Insecure choices require
    flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name       = string                # required — no default
    fifo_topic = optional(bool, false) # FIFO topics require a '.fifo' suffix on the name

    # --- Secure-by-default controls ---
    # PCI DSS Req 3: encryption at rest. Supply a CMK ARN to encrypt the topic.
    kms_key_arn = optional(string) # null = no CMK; only allowed when allow_unencrypted=true

    # PCI DSS Req 4: a default policy denies any Publish over a non-TLS transport.
    # Extra statements (object/list, merged into the policy) may be appended here.
    additional_policy_statements = optional(any, [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # ESCAPE HATCH: permit a topic with no encryption at rest (no CMK).
    # Requires a documented PCI exception (security@emag.ro).
    allow_unencrypted = optional(bool, false)
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
    condition     = can(tolist(var.config.additional_policy_statements))
    error_message = "config.additional_policy_statements must be a list of IAM policy statement objects."
  }
}
