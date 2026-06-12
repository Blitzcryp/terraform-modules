locals {
  module_tags = {
    Module = "components/rds-instance" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Engine-derived DB port when the caller does not pin one.
  is_postgres = var.config.engine == "postgres"
  db_port     = coalesce(var.config.db_port, local.is_postgres ? 5432 : 3306)

  # Create a dedicated CMK only when the caller did not bring their own key.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms[0].manifest.arn : var.config.kms_key_arn

  # Create a parameter group only when the caller supplied parameters.
  create_pg            = length(var.config.parameters) > 0
  parameter_group_name = local.create_pg ? module.parameter_group[0].manifest.name : null

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
    description = "Encrypts the ${var.config.name} RDS instance at rest"
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
    description = "Subnet group for the ${var.config.name} RDS instance"
    tags        = local.tags
  }
}

# --- DB security group (no public ingress; DB port from supplied sources only) -

module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-db"
    vpc_id        = var.config.vpc_id
    description   = "DB-port access for the ${var.config.name} RDS instance"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- Parameter group (created only when parameters are supplied) --------------

module "parameter_group" {
  source = "../../atoms/rds/rds-parameter-group"
  count  = local.create_pg ? 1 : 0

  config = {
    name        = "${var.config.name}-params"
    family      = var.config.parameter_group_family
    description = "Parameter group for the ${var.config.name} RDS instance"
    parameters  = var.config.parameters
    tags        = local.tags
  }
}

# --- RDS instance (secure by default) -----------------------------------------

module "instance" {
  source = "../../atoms/rds/rds-instance"

  config = {
    identifier             = var.config.name
    engine                 = var.config.engine
    engine_version         = var.config.engine_version
    instance_class         = var.config.instance_class
    allocated_storage      = var.config.allocated_storage
    db_subnet_group_name   = module.db_subnet_group.manifest.name
    vpc_security_group_ids = [module.security_group.manifest.id]
    port                   = local.db_port

    parameter_group_name = local.parameter_group_name

    storage_encrypted = true
    kms_key_arn       = local.kms_key_arn

    multi_az            = true
    deletion_protection = true

    iam_database_authentication_enabled = true
    manage_master_user_password         = true

    performance_insights_enabled = true

    backup_retention_period = var.config.backup_retention_period

    tags = local.tags

    # Forward escape hatches so an intentional, auditable relaxation is possible.
    allow_unencrypted = var.config.allow_unencrypted
    allow_deletion    = var.config.allow_deletion
    allow_public      = var.config.allow_public
  }
}
