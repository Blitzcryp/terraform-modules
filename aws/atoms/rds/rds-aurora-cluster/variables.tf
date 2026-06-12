variable "config" {
  description = <<-EOT
    Configuration for the Aurora cluster. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so passing
    only the required fields yields a compliant cluster. Insecure choices require
    flipping an explicit `allow_*` escape hatch (grep-able, auditable).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    cluster_identifier     = string       # required — cluster name
    db_subnet_group_name   = string       # required — where the cluster lives
    vpc_security_group_ids = list(string) # required — network exposure

    # --- Engine ---
    engine      = optional(string, "aurora-postgresql")
    engine_mode = optional(string, "provisioned")

    # --- Encryption at rest (PCI DSS Req 3: protect stored data) ---
    # storage_encrypted snapshots inherit the cluster's encryption automatically.
    storage_encrypted = optional(bool, true)
    kms_key_arn       = optional(string) # feeds kms_key_id; null = AWS-managed aws/rds key

    # --- Master credentials (PCI DSS Req 8: authenticate access) ---
    # COMPLIANCE: we NEVER accept a plaintext master_password. Static creds in
    # state/config violate PCI Req 8.2.1 (no clear-text). The password is created
    # and rotated in AWS Secrets Manager via manage_master_user_password.
    manage_master_user_password   = optional(bool, true)
    master_username               = optional(string, "dbadmin")
    master_user_secret_kms_key_id = optional(string) # KMS key for the managed secret

    # --- Authentication (PCI DSS Req 8) ---
    iam_database_authentication_enabled = optional(bool, true)

    # --- Backups (PCI DSS Req 10 / resilience: retained for forensics) ---
    backup_retention_period = optional(number, 14) # 7..35
    copy_tags_to_snapshot   = optional(bool, true)

    # --- Deletion safety ---
    deletion_protection = optional(bool, true)

    # --- Logging (PCI DSS Req 10: audit trails) ---
    # null => engine-appropriate default (postgresql vs the mysql audit set).
    enabled_cloudwatch_logs_exports = optional(list(string))

    # --- Windows ---
    preferred_backup_window      = optional(string) # e.g. "02:00-03:00" (UTC)
    preferred_maintenance_window = optional(string) # e.g. "sun:03:30-sun:04:30"

    # --- Serverless v2 (optional use-case). When set, instances must use
    #     instance_class = "db.serverless". ---
    serverlessv2_scaling_configuration = optional(object({
      min_capacity = number
      max_capacity = number
    }))

    # --- Instances ---
    instance_count                  = optional(number, 2)
    instance_class                  = optional(string, "db.r6g.large")
    performance_insights_enabled    = optional(bool, true)
    performance_insights_kms_key_id = optional(string)

    # Patch hygiene: pull in minor engine fixes automatically (PCI DSS Req 6).
    auto_minor_version_upgrade = optional(bool, true)

    # Enhanced monitoring (PCI DSS Req 10). 0 disables; a positive interval needs
    # an IAM role ARN supplied by the caller (atoms never create dependencies).
    monitoring_interval = optional(number, 60)
    monitoring_role_arn = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false
    allow_deletion    = optional(bool, false) # permit deletion_protection=false
  })
  # no `default` — cluster_identifier / db_subnet_group_name / vpc_security_group_ids are required

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.config.engine)
    error_message = "config.engine must be aurora-mysql or aurora-postgresql."
  }

  validation {
    condition     = var.config.backup_retention_period >= 7 && var.config.backup_retention_period <= 35
    error_message = "config.backup_retention_period must be between 7 and 35 (PCI Req 10 wants retained backups)."
  }

  validation {
    condition     = var.config.instance_count >= 1
    error_message = "config.instance_count must be at least 1."
  }
}
