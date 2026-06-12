variable "config" {
  description = <<-EOT
    Configuration for the standalone RDS instance. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    passing only the required fields yields a compliant instance: encrypted at
    rest, Multi-AZ, deletion protection on, 14-day backups, IAM auth on, the
    master password managed in Secrets Manager (never plaintext), Performance
    Insights on, and not publicly accessible. Insecure choices require flipping an
    explicit `allow_*` escape hatch (grep-able, auditable).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    identifier             = string       # required — DB identifier
    engine                 = string       # required — e.g. postgres | mysql | mariadb
    db_subnet_group_name   = string       # required — where the instance lives
    vpc_security_group_ids = list(string) # required — network exposure

    # --- Engine / sizing ---
    engine_version        = optional(string)
    instance_class        = optional(string, "db.t3.medium")
    allocated_storage     = optional(number, 20)
    max_allocated_storage = optional(number, 100) # storage autoscaling ceiling

    # --- Encryption at rest (PCI DSS Req 3: protect stored data) ---
    # storage_encrypted snapshots inherit the instance's encryption automatically.
    storage_encrypted = optional(bool, true)
    kms_key_arn       = optional(string) # feeds kms_key_id; null = AWS-managed aws/rds key

    # --- High availability / safety ---
    multi_az            = optional(bool, true)
    deletion_protection = optional(bool, true)

    # --- Master credentials (PCI DSS Req 8: authenticate access) ---
    # COMPLIANCE: we NEVER accept a plaintext master_password. Static creds in
    # state/config violate PCI Req 8.2.1 (no clear-text). The password is created
    # and rotated in AWS Secrets Manager via manage_master_user_password.
    manage_master_user_password = optional(bool, true)
    master_username             = optional(string, "dbadmin")

    # --- Authentication (PCI DSS Req 8) ---
    iam_database_authentication_enabled = optional(bool, true)

    # --- Backups (PCI DSS Req 10 / resilience: retained for forensics) ---
    backup_retention_period = optional(number, 14) # 7..35
    copy_tags_to_snapshot   = optional(bool, true)

    # --- Patch hygiene (PCI DSS Req 6) ---
    auto_minor_version_upgrade = optional(bool, true)

    # --- Monitoring (PCI DSS Req 10) ---
    performance_insights_enabled = optional(bool, true)

    # --- Logging (PCI DSS Req 10: audit trails) ---
    # null => engine default log set chosen in main.tf.
    enabled_cloudwatch_logs_exports = optional(list(string))

    # --- Network ---
    publicly_accessible = optional(bool, false)
    port                = optional(number)

    # --- Optional groups ---
    parameter_group_name = optional(string)
    option_group_name    = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false
    allow_deletion    = optional(bool, false) # permit deletion_protection=false
    allow_public      = optional(bool, false) # permit publicly_accessible=true
  })
  # no `default` — identifier / engine / db_subnet_group_name / vpc_security_group_ids are required

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.config.engine)
    error_message = "config.engine must be postgres, mysql, or mariadb."
  }

  validation {
    condition     = var.config.backup_retention_period >= 7 && var.config.backup_retention_period <= 35
    error_message = "config.backup_retention_period must be between 7 and 35 (PCI Req 10 wants retained backups)."
  }

  validation {
    condition     = var.config.port == null || (var.config.port >= 1 && var.config.port <= 65535)
    error_message = "config.port must be a valid TCP port (1-65535)."
  }
}
