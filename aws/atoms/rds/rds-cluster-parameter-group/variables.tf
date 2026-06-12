variable "config" {
  description = <<-EOT
    Configuration for the RDS cluster parameter group. All inputs live on this
    single object. The caller supplies the name and the cluster engine family;
    parameters are optional. Use this for Aurora / multi-AZ DB clusters.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name   = string # required — cluster parameter group name
    family = string # required — cluster parameter group family, e.g. aurora-postgresql16

    description = optional(string, "Managed by terraform (atoms/rds-cluster-parameter-group)")

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
