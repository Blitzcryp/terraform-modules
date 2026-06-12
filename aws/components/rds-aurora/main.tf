locals {
  module_tags = {
    Module = "components/rds-aurora" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Engine-derived DB port when the caller does not pin one.
  is_mysql = var.config.engine == "aurora-mysql"
  db_port  = coalesce(var.config.db_port, local.is_mysql ? 3306 : 5432)

  # Create a dedicated CMK only when the caller did not bring their own key.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms[0].manifest.arn : var.config.kms_key_arn

  # DB-port ingress rules: one per allowed app security group and one per CIDR.
  # No public (0.0.0.0/0) ingress is ever generated here (PCI DSS Req 1).
  sg_ingress_rules = [
    for sg in var.config.allowed_security_group_ids : {
      description                  = "DB-port ingress from app security group ${sg}"
      ip_protocol                  = "tcp"
      from_port                    = local.db_port
      to_port                      = local.db_port
      referenced_security_group_id = sg
    }
  ]
  cidr_ingress_rules = [
    for c in var.config.allowed_cidrs : {
      description = "DB-port ingress from CIDR ${c}"
      ip_protocol = "tcp"
      from_port   = local.db_port
      to_port     = local.db_port
      cidr_ipv4   = c
    }
  ]
  ingress_rules = concat(local.sg_ingress_rules, local.cidr_ingress_rules)
}

# --- Encryption key (created only when no BYO key is supplied) ----------------

module "kms" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Encrypts the ${var.config.name} Aurora cluster at rest"
    alias       = "rds/${var.config.name}"
    tags        = local.tags
  }
}

# --- DB subnet group ----------------------------------------------------------

module "db_subnet_group" {
  source = "../../atoms/rds/db-subnet-group"

  config = {
    name        = var.config.name
    subnet_ids  = var.config.subnet_ids
    description = "Subnet group for the ${var.config.name} Aurora cluster"
    tags        = local.tags
  }
}

# --- DB security group (no public ingress; DB port from supplied sources only) -

module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-db"
    vpc_id        = var.config.vpc_id
    description   = "DB-port access for the ${var.config.name} Aurora cluster"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- Aurora cluster (secure by default) ---------------------------------------

module "cluster" {
  source = "../../atoms/rds/rds-aurora-cluster"

  config = {
    cluster_identifier     = var.config.name
    db_subnet_group_name   = module.db_subnet_group.manifest.name
    vpc_security_group_ids = [module.security_group.manifest.id]

    engine         = var.config.engine
    instance_count = var.config.instance_count
    instance_class = var.config.instance_class

    storage_encrypted = true
    kms_key_arn       = local.kms_key_arn

    iam_database_authentication_enabled = true
    manage_master_user_password         = true

    backup_retention_period = var.config.backup_retention_period
    deletion_protection     = true

    monitoring_interval = var.config.monitoring_interval
    monitoring_role_arn = var.config.monitoring_role_arn

    tags = local.tags

    # Forward escape hatches so an intentional, auditable relaxation is possible.
    allow_unencrypted = var.config.allow_unencrypted
    allow_deletion    = var.config.allow_deletion
  }
}
