variable "config" {
  description = <<-EOT
    Configuration for the AWS Backup plan atom. All inputs live on this single
    object. A plan is a set of rules (schedule + retention lifecycle) that drive
    when recovery points are taken and how long they are kept (PCI DSS Req 10/12).
    PCI-compliant defaults (daily schedule, 35-day retention) are baked into the
    rule's optional() fields.
  EOT

  type = object({
    # name is REQUIRED: the caller must decide the plan name. No default.
    name = string

    # rules is REQUIRED: a plan must have at least one backup rule.
    rules = list(object({
      rule_name         = string
      target_vault_name = string
      schedule          = optional(string, "cron(0 5 * * ? *)") # daily at 05:00 UTC
      start_window      = optional(number, 60)                  # minutes
      completion_window = optional(number, 180)                 # minutes
      # Lifecycle (PCI DSS Req 10.5.1 retention): days before cold storage / delete.
      cold_storage_after = optional(number) # null = never transition to cold storage
      delete_after       = optional(number, 35)
      # Cross-region/cross-account copy target (DR). null = no copy action.
      copy_action_destination_vault_arn = optional(string)
    }))

    # Pass-through for plugin-specific options (e.g. Windows VSS). Defaults empty.
    advanced_backup_settings = optional(any, [])

    tags = optional(map(string), {})
  })

  # no `default` here because name and rules are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.rules) > 0
    error_message = "config.rules must contain at least one backup rule."
  }

  validation {
    condition     = alltrue([for r in var.config.rules : r.delete_after == null || r.delete_after >= 1])
    error_message = "Each rule's delete_after, when set, must be at least 1 day."
  }

  validation {
    condition = alltrue([
      for r in var.config.rules :
      r.cold_storage_after == null || r.delete_after == null || r.delete_after >= r.cold_storage_after + 90
    ])
    error_message = "When a rule sets cold_storage_after, delete_after must be at least cold_storage_after + 90 (AWS Backup minimum cold-storage duration)."
  }
}
