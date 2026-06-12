variable "config" {
  description = <<-EOT
    Configuration for the ECS cluster. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so passing
    only the required `name` yields a compliant cluster (Container Insights on,
    encrypted ECS Exec audit logging when a KMS key + log group are supplied).
    Insecure choices require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name = string # required — cluster name

    # --- Secure-by-default controls ---
    # Container Insights = observability/monitoring (PCI DSS Req 10: track & monitor access).
    enable_container_insights = optional(bool, true)

    # ECS Exec audit logging to CloudWatch, encrypted with a CMK (PCI DSS Req 10 / Req 3).
    # When both kms_key_arn and execute_command_log_group_name are set, exec sessions are
    # logged to CloudWatch with cloud_watch_encryption_enabled = true.
    kms_key_arn                    = optional(string) # CMK ARN for ECS Exec session encryption
    execute_command_log_group_name = optional(string) # CloudWatch log group for ECS Exec audit logs

    # Fargate-only capacity by default (no unmanaged EC2 capacity to patch — Req 6/2).
    capacity_providers = optional(list(string), ["FARGATE", "FARGATE_SPOT"])
    default_capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      base              = optional(number)
      weight            = optional(number)
    })), [])

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Disabling Container Insights removes monitoring telemetry; requires a PCI exception.
    allow_container_insights_disabled = optional(bool, false)
  })
  # no `default` because `name` is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.config.name))
    error_message = "config.name must be 1-255 chars of letters, numbers, hyphens, or underscores."
  }
}
