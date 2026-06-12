variable "config" {
  description = <<-EOT
    Configuration for the DB subnet group. All inputs live on this single object.
    The caller supplies the name and the (private) subnet IDs; everything else has
    a sensible default.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # required — subnet group name
    subnet_ids = list(string) # required — subnets the DB may live in

    description = optional(string, "Managed by terraform (atoms/db-subnet-group)")
    tags        = optional(map(string), {})
  })
  # no `default` — name and subnet_ids are required

  validation {
    condition     = length(var.config.subnet_ids) >= 2
    error_message = "config.subnet_ids must list at least two subnets in distinct AZs for Multi-AZ DB resilience."
  }
}
