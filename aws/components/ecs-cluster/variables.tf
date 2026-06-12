variable "config" {
  description = <<-EOT
    Configuration for the ecs-cluster component (a Fargate ECS cluster with
    encrypted ECS Exec / container audit logging). All inputs live on this single
    object. PCI-compliant defaults are baked into the optional() fields, so the
    caller only has to supply the required `name`: Container Insights on, a
    CloudWatch-Logs-authorised CMK created when no BYO key is supplied, an
    encrypted log group with 365-day retention, and Fargate-only capacity.
  EOT

  type = object({
    # name is REQUIRED: the cluster name (also used for the log group and KMS
    # alias). The caller must decide it. No default.
    name = string

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---
    # BYOK: if set, no kms-key atom is created and this key encrypts the log group
    # and ECS Exec sessions. Otherwise the component owns a CMK.
    kms_key_arn = optional(string)

    log_retention_days = optional(number, 365) # >= 1 year of audit logs

    # Fargate-only capacity by default (no unmanaged EC2 capacity to patch).
    capacity_providers = optional(list(string), ["FARGATE", "FARGATE_SPOT"])

    tags = optional(map(string), {})
  })
  # no `default` here because name is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.config.name))
    error_message = "config.name must be 1-255 chars of letters, numbers, hyphens, or underscores."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
