variable "config" {
  description = <<-EOT
    Configuration for the rds-instance component (a standalone, secure-by-default
    RDS database). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked into the optional() fields: storage is encrypted, the
    instance is Multi-AZ, deletion protection is on, backups are retained, IAM
    auth is on, and the master password is managed in Secrets Manager (never
    plaintext). The DB security group has NO public ingress — only the supplied
    app security groups / CIDRs may reach the DB port. Required fields (name,
    vpc_id, subnet_ids) have no default, so config cannot be omitted.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # required — DB identifier
    vpc_id     = string       # required — VPC for the DB security group
    subnet_ids = list(string) # required — private subnets for the DB subnet group

    # --- Engine / sizing ---
    engine            = optional(string, "postgres")
    engine_version    = optional(string)
    instance_class    = optional(string, "db.t3.medium")
    allocated_storage = optional(number, 20)

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # DB-port ingress is allowed ONLY from these app security groups / CIDRs.
    # Empty lists => a DB security group with no ingress at all (most locked-down).
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # Engine-derived default (5432 for postgres, 3306 for mysql/mariadb) when null.
    db_port = optional(number)

    # --- Parameter group (created only when parameters is non-empty) ---
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    parameter_group_family = optional(string) # required when parameters is non-empty

    # --- Backups (PCI DSS Req 10 / resilience) ---
    backup_retention_period = optional(number, 14) # 7..35

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false
    allow_deletion    = optional(bool, false) # permit deletion_protection=false
    allow_public      = optional(bool, false) # permit publicly_accessible=true
  })
  # no `default` — name, vpc_id and subnet_ids are required

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.config.engine)
    error_message = "config.engine must be postgres, mysql, or mariadb."
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
    condition     = var.config.db_port == null || (var.config.db_port >= 1 && var.config.db_port <= 65535)
    error_message = "config.db_port must be a valid TCP port (1-65535)."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = length(var.config.parameters) == 0 || var.config.parameter_group_family != null
    error_message = "config.parameter_group_family is required when config.parameters is non-empty (e.g. postgres16)."
  }
}
