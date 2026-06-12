variable "config" {
  description = <<-EOT
    Configuration for the rds-aurora component (a provisioned, secure-by-default
    Aurora cluster). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked into the optional() fields: storage is encrypted, deletion
    protection is on, backups are retained, IAM auth is on, and the master
    password is managed in Secrets Manager (never plaintext). The DB security
    group has NO public ingress — only the supplied app security groups / CIDRs
    may reach the DB port. Required fields (name, vpc_id, subnet_ids) have no
    default, so config cannot be omitted.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # required — cluster_identifier
    vpc_id     = string       # required — VPC for the DB security group
    subnet_ids = list(string) # required — private subnets for the DB subnet group

    # --- Engine / sizing ---
    engine         = optional(string, "aurora-postgresql")
    instance_count = optional(number, 2)
    instance_class = optional(string, "db.r6g.large")

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # DB-port ingress is allowed ONLY from these app security groups / CIDRs.
    # Empty lists => a DB security group with no ingress at all (most locked-down).
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # Engine-derived default (5432 for postgresql, 3306 for mysql) when null.
    db_port = optional(number)

    # --- Backups (PCI DSS Req 10 / resilience) ---
    backup_retention_period = optional(number, 14) # 7..35

    # Enhanced OS monitoring (PCI DSS Req 10). monitoring_interval defaults to 0
    # because a positive interval requires a caller-supplied monitoring_role_arn
    # (the cluster atom takes the ARN as input — it never creates the role).
    monitoring_interval = optional(number, 0)
    monitoring_role_arn = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false
    allow_deletion    = optional(bool, false) # permit deletion_protection=false
  })
  # no `default` — name, vpc_id and subnet_ids are required

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.config.engine)
    error_message = "config.engine must be aurora-mysql or aurora-postgresql."
  }

  validation {
    condition     = length(var.config.subnet_ids) >= 2
    error_message = "config.subnet_ids must list at least two subnets in distinct AZs for Multi-AZ resilience."
  }

  validation {
    condition     = var.config.backup_retention_period >= 7 && var.config.backup_retention_period <= 35
    error_message = "config.backup_retention_period must be between 7 and 35 (PCI DSS Req 10 wants retained backups)."
  }

  validation {
    condition     = var.config.instance_count >= 1
    error_message = "config.instance_count must be at least 1."
  }

  validation {
    condition     = var.config.db_port == null || (var.config.db_port >= 1 && var.config.db_port <= 65535)
    error_message = "config.db_port must be a valid TCP port (1-65535)."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = var.config.monitoring_interval == 0 || var.config.monitoring_role_arn != null
    error_message = "config.monitoring_interval > 0 requires config.monitoring_role_arn (the cluster atom takes the role ARN as input)."
  }
}
