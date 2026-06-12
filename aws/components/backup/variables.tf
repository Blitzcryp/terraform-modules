variable "config" {
  description = <<-EOT
    Configuration for the backup component (PCI DSS Req 9/10/12: encrypted,
    optionally immutable backups with enforced retention). All inputs live on
    this single object. PCI-compliant defaults are baked into the optional()
    fields, so the caller only has to supply the required `name`:
      - a customer-managed CMK is created (usable by AWS Backup) unless a BYO
        kms_key_arn is supplied,
      - a daily backup plan with 35-day retention is created,
      - every resource tagged Backup=true is selected for backup,
      - a least-privilege AWS Backup service role is created.
  EOT

  type = object({
    # name is REQUIRED: base name for the vault, plan, selection, role and KMS
    # alias. The caller must decide it. No default.
    name = string

    # --- Encryption (PCI DSS Req 3) ------------------------------------------
    # BYO CMK ARN. When null the component creates a CMK authorised for AWS Backup.
    kms_key_arn = optional(string)

    # --- Backup schedule & retention (PCI DSS Req 10.5.1 / Req 12) -----------
    schedule                = optional(string, "cron(0 5 * * ? *)") # daily 05:00 UTC
    start_window            = optional(number, 60)                  # minutes
    completion_window       = optional(number, 180)                 # minutes
    cold_storage_after_days = optional(number)                      # null = never
    delete_after_days       = optional(number, 35)                  # retention

    # --- Vault Lock (WORM immutability, PCI DSS Req 10.5 / Req 12) ------------
    enable_vault_lock  = optional(bool, false)
    lock_mode          = optional(string, "governance")
    min_retention_days = optional(number)
    max_retention_days = optional(number)

    # --- What to back up ------------------------------------------------------
    # Tag-based selection (default: every resource tagged Backup=true). Rendered
    # as STRINGEQUALS selection tags. Combine with explicit resource_arns.
    selection_tags = optional(map(string), { Backup = "true" })
    resource_arns  = optional(list(string), [])

    tags = optional(map(string), {})
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = contains(["governance", "compliance"], var.config.lock_mode)
    error_message = "config.lock_mode must be either \"governance\" or \"compliance\"."
  }

  validation {
    condition     = length(var.config.selection_tags) > 0 || length(var.config.resource_arns) > 0
    error_message = "The backup must target something: set config.selection_tags and/or config.resource_arns."
  }
}
