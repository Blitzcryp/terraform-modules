variable "config" {
  description = <<-EOT
    Configuration for the Amazon MQ broker. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields: private (not
    publicly accessible), encrypted with a customer-managed KMS key, general + audit
    logging on. Insecure choices require flipping an explicit `allow_*` escape hatch.

    SECURITY: broker user passwords are sensitive. They MUST be supplied from a
    secrets manager (AWS Secrets Manager / SSM SecureString / tfvars sourced from a
    vault), never committed to source control (PCI DSS Req 8). This variable is
    marked sensitive so plan/apply output never echoes the passwords.
  EOT

  type = object({
    broker_name = string # required

    # --- Engine ---
    engine_type    = optional(string, "ActiveMQ")
    engine_version = optional(string) # null = provider/account default for engine

    # --- Placement ---
    host_instance_type = optional(string, "mq.m5.large")
    deployment_mode    = optional(string, "ACTIVE_STANDBY_MULTI_AZ")
    subnet_ids         = list(string) # required
    security_groups    = list(string) # required

    # --- Network exposure (PCI DSS Req 1) ---
    publicly_accessible = optional(bool, false) # secure default
    # ESCAPE HATCH: permit publicly_accessible=true. Requires a documented exception.
    allow_public = optional(bool, false)

    # --- Encryption at rest (PCI DSS Req 3) ---
    kms_key_arn = optional(string) # customer-managed CMK; null falls back to AWS-owned
    # ESCAPE HATCH: permit use of the AWS-owned key when no CMK is supplied.
    allow_aws_owned_key = optional(bool, false)

    # --- Patching ---
    auto_minor_version_upgrade = optional(bool, true)

    # --- Logging (PCI DSS Req 10) ---
    general_logs = optional(bool, true)
    audit_logs   = optional(bool, true) # only valid for ActiveMQ; guarded in main.tf

    # --- Broker users (PCI DSS Req 8) ---
    # Passwords MUST come from a secrets manager / tfvars-from-secret, NOT source control.
    users = list(object({
      username       = string
      password       = string # sensitive — sourced from a vault, never hardcoded
      console_access = optional(bool, false)
      groups         = optional(list(string), [])
    }))

    tags = optional(map(string), {})
  })

  sensitive = true # protects the embedded user passwords (PCI DSS Req 8)

  # no `default` here because broker_name / subnet_ids / security_groups / users are required

  validation {
    condition     = contains(["ActiveMQ", "RabbitMQ"], var.config.engine_type)
    error_message = "config.engine_type must be ActiveMQ or RabbitMQ."
  }

  validation {
    condition     = contains(["SINGLE_INSTANCE", "ACTIVE_STANDBY_MULTI_AZ", "CLUSTER_MULTI_AZ"], var.config.deployment_mode)
    error_message = "config.deployment_mode must be SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ, or CLUSTER_MULTI_AZ."
  }

  validation {
    condition     = length(var.config.users) >= 1
    error_message = "config.users must contain at least one broker user (username + password from a secrets manager)."
  }
}
