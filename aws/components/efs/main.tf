locals {
  module_tags = {
    Module = "components/efs" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated CMK only when the caller did not bring their own key.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms[0].manifest.arn : var.config.kms_key_arn

  nfs_port = 2049

  # NFS ingress rules: one per allowed app security group and one per CIDR.
  # No public (0.0.0.0/0) ingress is ever generated here (PCI DSS Req 1).
  sg_ingress_rules = [
    for sg in var.config.allowed_security_group_ids : {
      description                  = "NFS ingress from app security group ${sg}"
      ip_protocol                  = "tcp"
      from_port                    = local.nfs_port
      to_port                      = local.nfs_port
      referenced_security_group_id = sg
    }
  ]
  cidr_ingress_rules = [
    for c in var.config.allowed_cidrs : {
      description = "NFS ingress from CIDR ${c}"
      ip_protocol = "tcp"
      from_port   = local.nfs_port
      to_port     = local.nfs_port
      cidr_ipv4   = c
    }
  ]
  ingress_rules = concat(local.sg_ingress_rules, local.cidr_ingress_rules)

  # Stable index per subnet so mount targets are addressed by subnet id.
  mount_targets = { for s in var.config.subnet_ids : s => s }
}

# --- Encryption key (created only when no BYO key is supplied) ----------------

module "kms" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Encrypts the ${var.config.name} EFS file system at rest"
    alias       = "efs/${var.config.name}"
    tags        = local.tags
  }
}

# --- Mount-target security group (no public ingress; NFS 2049 only) -----------

module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-efs"
    vpc_id        = var.config.vpc_id
    description   = "NFS (2049) access for the ${var.config.name} EFS file system"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- EFS file system (encrypted at rest, TLS-only access policy) ---------------

module "file_system" {
  source = "../../atoms/efs/efs-file-system"

  config = {
    name             = var.config.name
    encrypted        = true
    kms_key_arn      = local.kms_key_arn
    performance_mode = var.config.performance_mode
    enforce_tls      = true
    tags             = local.tags
  }
}

# --- Mount targets (one per subnet) -------------------------------------------

module "mount_target" {
  source   = "../../atoms/efs/efs-mount-target"
  for_each = local.mount_targets

  config = {
    file_system_id  = module.file_system.manifest.id
    subnet_id       = each.value
    security_groups = [module.security_group.manifest.id]
  }
}

# --- Access points (optional; least-privilege POSIX entry points) -------------

module "access_point" {
  source   = "../../atoms/efs/efs-access-point"
  for_each = var.config.access_points

  config = {
    file_system_id = module.file_system.manifest.id
    posix_user     = each.value.posix_user
    root_directory = each.value.root_directory
    tags           = local.tags
  }
}
