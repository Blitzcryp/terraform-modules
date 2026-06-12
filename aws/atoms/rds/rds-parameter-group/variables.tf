variable "config" {
  description = <<-EOT
    Configuration for the DB parameter group. All inputs live on this single
    object. The caller supplies the name and the engine family; parameters are
    optional. Use this for standalone (non-Aurora) RDS instances.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name   = string # required — parameter group name
    family = string # required — DB parameter group family, e.g. postgres16, mysql8.0

    description = optional(string, "Managed by terraform (atoms/rds-parameter-group)")

    # Each parameter sets one engine tunable. apply_method is "immediate" (default)
    # or "pending-reboot" for static parameters.
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])

    tags = optional(map(string), {})
  })
  # no `default` — name and family are required

  validation {
    condition     = alltrue([for p in var.config.parameters : contains(["immediate", "pending-reboot"], p.apply_method)])
    error_message = "Each config.parameters apply_method must be immediate or pending-reboot."
  }
}
