variable "config" {
  description = <<-EOT
    Configuration for the AWS Backup vault atom. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    the caller only has to supply the required `name`. Insecure choices (a vault
    without a customer-managed CMK) require flipping an explicit `allow_*` escape
    hatch.

    Optional Vault Lock (WORM immutability, PCI DSS Req 9/10/12) is configured on
    the same object and rendered as a tightly-coupled
    aws_backup_vault_lock_configuration sub-resource.
  EOT

  type = object({
    # name is REQUIRED: the caller must decide the vault name. No default.
    name = string

    # --- Secure-by-default controls (PCI DSS Req 3: protect stored data) ---
    # KMS CMK encrypting recovery points. When null AWS Backup falls back to an
    # AWS-managed key, which is only permitted when allow_unencrypted = true.
    kms_key_arn = optional(string)

    # --- Vault Lock (WORM immutability, PCI DSS Req 10.5 / Req 12) -------------
    # governance: can be removed by a principal with sufficient IAM permissions.
    # compliance: immutable — cannot be changed or deleted after the
    #             changeable_for_days cooling-off window elapses.
    enable_lock        = optional(bool, false)
    lock_mode          = optional(string, "governance")
    min_retention_days = optional(number)
    max_retention_days = optional(number)
    # Compliance-mode cooling-off: the vault lock can still be removed within
    # this many days; afterwards it is permanently immutable. Only applied in
    # compliance mode (its presence is what selects compliance mode).
    changeable_for_days = optional(number, 3)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit a vault without a customer-managed CMK (AWS-managed key fallback).
    allow_unencrypted = optional(bool, false)
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = contains(["governance", "compliance"], var.config.lock_mode)
    error_message = "config.lock_mode must be either \"governance\" or \"compliance\"."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition = (
      var.config.min_retention_days == null ||
      var.config.max_retention_days == null ||
      var.config.max_retention_days >= var.config.min_retention_days
    )
    error_message = "config.max_retention_days must be greater than or equal to config.min_retention_days."
  }
}
