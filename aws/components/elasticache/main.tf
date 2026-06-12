locals {
  module_tags = {
    Module = "components/elasticache" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated CMK only when the caller did not bring their own key.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms[0].manifest.arn : var.config.kms_key_arn

  # Redis-port ingress rules: one per allowed app security group and one per CIDR.
  # No public (0.0.0.0/0) ingress is ever generated here (PCI DSS Req 1).
  sg_ingress_rules = [
    for sg in var.config.allowed_security_group_ids : {
      description                  = "Redis-port ingress from app security group ${sg}"
      ip_protocol                  = "tcp"
      from_port                    = var.config.port
      to_port                      = var.config.port
      referenced_security_group_id = sg
    }
  ]
  cidr_ingress_rules = [
    for c in var.config.allowed_cidrs : {
      description = "Redis-port ingress from CIDR ${c}"
      ip_protocol = "tcp"
      from_port   = var.config.port
      to_port     = var.config.port
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
    description = "Encrypts the ${var.config.name} Redis cache at rest"
    alias       = "elasticache/${var.config.name}"
    tags        = local.tags
  }
}

# --- Cache subnet group -------------------------------------------------------

module "subnet_group" {
  source = "../../atoms/elasticache/elasticache-subnet-group"

  config = {
    name        = var.config.name
    subnet_ids  = var.config.subnet_ids
    description = "Subnet group for the ${var.config.name} Redis cache"
    tags        = local.tags
  }
}

# --- Cache security group (no public ingress; Redis port from supplied sources) -

module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-cache"
    vpc_id        = var.config.vpc_id
    description   = "Redis-port access for the ${var.config.name} cache"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- Redis replication group (secure by default) ------------------------------

module "replication_group" {
  source = "../../atoms/elasticache/elasticache-replication-group"

  config = {
    replication_group_id = var.config.name
    description          = "Redis cache for ${var.config.name}"
    subnet_group_name    = module.subnet_group.manifest.name
    security_group_ids   = [module.security_group.manifest.id]

    engine_version     = var.config.engine_version
    node_type          = var.config.node_type
    port               = var.config.port
    num_cache_clusters = var.config.num_cache_clusters

    # Encryption at rest with the component-owned (or BYO) CMK (PCI DSS Req 3).
    at_rest_encryption_enabled = true
    kms_key_arn                = local.kms_key_arn

    # Encryption in transit (PCI DSS Req 4).
    transit_encryption_enabled = true

    # Access control (PCI DSS Req 8). SECURITY: must originate from a secrets
    # manager — never a literal in source.
    auth_token = var.config.auth_token

    tags = local.tags
  }
}
