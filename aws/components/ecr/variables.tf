variable "config" {
  description = <<-EOT
    Configuration for the ecr component (a scanning-enabled, KMS-encrypted image
    registry). All inputs live on this single object. PCI-compliant defaults are
    baked into the optional() fields, so the caller only has to supply the
    required `name`: a repository with scan-on-push (Req 6), immutable tags
    (image integrity), CMK encryption at rest (Req 3) and a lifecycle policy,
    plus account-level Inspector ECR scanning (Req 6 & 11).
  EOT

  type = object({
    name = string # required — the repository name

    # --- Secure-by-default controls ---
    # PCI DSS Req 3: encryption at rest. BYO CMK ARN; null = this component
    # creates a CMK for the repository.
    kms_key_arn = optional(string)
    # Lifecycle policy: expire untagged images after N days.
    untagged_expiry_days = optional(number, 14)
    # PCI DSS Req 6 & 11: enable Amazon Inspector ECR scanning at the account
    # level. Set false to skip the inspector2-enabler atom.
    enable_inspector = optional(bool, true)
    # Optional resource-based repository policy JSON.
    additional_repository_policy = optional(string)

    tags = optional(map(string), {})
  })
  # `name` is required, so no `default = {}`.

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty repository name."
  }

  validation {
    condition     = var.config.untagged_expiry_days >= 1
    error_message = "config.untagged_expiry_days must be >= 1."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
