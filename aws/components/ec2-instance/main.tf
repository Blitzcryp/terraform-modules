locals {
  module_tags = {
    Module = "components/ec2-instance" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated CMK only when the caller did not bring their own key.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms[0].manifest.arn : var.config.kms_key_arn

  # EC2 service trust policy for the instance role (PCI DSS Req 7/8: least
  # privilege identity assumed only by the EC2 service).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  # Instance ingress: one rule per allowed app SG and one per CIDR, plus any
  # explicit caller rules. No public (0.0.0.0/0) ingress is generated here
  # (PCI DSS Req 1) — the security-group atom rejects it without an escape hatch.
  sg_ingress_rules = [
    for sg in var.config.allowed_security_group_ids : {
      description                  = "Ingress from app security group ${sg}"
      ip_protocol                  = "-1"
      referenced_security_group_id = sg
    }
  ]
  cidr_ingress_rules = [
    for c in var.config.allowed_cidrs : {
      description = "Ingress from CIDR ${c}"
      ip_protocol = "-1"
      cidr_ipv4   = c
    }
  ]
  ingress_rules = concat(local.sg_ingress_rules, local.cidr_ingress_rules, var.config.ingress_rules)
}

# --- Encryption key (created only when no BYO key is supplied) ----------------
module "kms" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Encrypts the ${var.config.name} EC2 instance volumes at rest"
    alias       = "ec2/${var.config.name}"
    tags        = local.tags
  }
}

# --- Instance security group (no public ingress) ------------------------------
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-ec2"
    vpc_id        = var.config.vpc_id
    description   = "Instance access for ${var.config.name}"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- Instance IAM role (assumed by EC2) ---------------------------------------
module "role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name               = "${var.config.name}-ec2"
    assume_role_policy = local.assume_role_policy
    description        = "Instance role for ${var.config.name}"
    # e.g. AmazonSSMManagedInstanceCore for SSM Session Manager (PCI DSS Req 8).
    managed_policy_arns = var.config.managed_policy_arns
    tags                = local.tags
  }
}

# --- Instance profile wrapping the role ---------------------------------------
module "instance_profile" {
  source = "../../atoms/iam/iam-instance-profile"

  config = {
    name = "${var.config.name}-ec2"
    role = module.role.manifest.name
    tags = local.tags
  }
}

# --- EC2 instance (secure by default) -----------------------------------------
module "instance" {
  source = "../../atoms/ec2/ec2-instance"

  config = {
    ami                    = var.config.ami
    instance_type          = var.config.instance_type
    subnet_id              = var.config.subnet_id
    vpc_security_group_ids = [module.security_group.manifest.id]
    iam_instance_profile   = module.instance_profile.manifest.name
    user_data              = var.config.user_data

    root_volume_size = var.config.root_volume_size
    kms_key_arn      = local.kms_key_arn

    # No public IP (PCI DSS Req 1); IMDSv2 enforced (PCI DSS Req 2). Forward the
    # escape hatches so an intentional, auditable relaxation is possible.
    allow_imdsv1      = var.config.allow_imdsv1
    allow_unencrypted = var.config.allow_unencrypted

    tags = local.tags
  }
}
