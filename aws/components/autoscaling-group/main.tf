locals {
  module_tags = {
    Module = "components/autoscaling-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated CMK only when the caller did not bring their own key.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms[0].manifest.arn : var.config.kms_key_arn

  # EC2 service trust policy for the instance role (PCI DSS Req 7/8).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  # When a load balancer target group is attached, use ELB health checks so the
  # ASG replaces instances the LB considers unhealthy.
  load_balanced     = length(var.config.target_group_arns) > 0
  health_check_type = local.load_balanced ? "ELB" : "EC2"

  # Instance ingress: one rule per allowed app SG and one per CIDR, plus any
  # explicit caller rules. No public (0.0.0.0/0) ingress is generated here.
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
    description = "Encrypts the ${var.config.name} ASG instance volumes at rest"
    alias       = "asg/${var.config.name}"
    tags        = local.tags
  }
}

# --- Instance security group (no public ingress) ------------------------------
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-asg"
    vpc_id        = var.config.vpc_id
    description   = "Instance access for ${var.config.name} ASG"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- Instance IAM role (assumed by EC2) ---------------------------------------
module "role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name                = "${var.config.name}-asg"
    assume_role_policy  = local.assume_role_policy
    description         = "ASG instance role for ${var.config.name}"
    managed_policy_arns = var.config.managed_policy_arns
    tags                = local.tags
  }
}

# --- Instance profile wrapping the role ---------------------------------------
module "instance_profile" {
  source = "../../atoms/iam/iam-instance-profile"

  config = {
    name = "${var.config.name}-asg"
    role = module.role.manifest.name
    tags = local.tags
  }
}

# --- Launch template (IMDSv2, encrypted root, detailed monitoring) ------------
module "launch_template" {
  source = "../../atoms/ec2/launch-template"

  config = {
    name                     = var.config.name
    image_id                 = var.config.image_id
    instance_type            = var.config.instance_type
    vpc_security_group_ids   = [module.security_group.manifest.id]
    iam_instance_profile_arn = module.instance_profile.manifest.arn
    user_data                = var.config.user_data
    root_volume_size         = var.config.root_volume_size
    kms_key_arn              = local.kms_key_arn

    # Forward escape hatches so an intentional, auditable relaxation is possible.
    allow_imdsv1      = var.config.allow_imdsv1
    allow_unencrypted = var.config.allow_unencrypted

    tags = local.tags
  }
}

# --- Auto Scaling group -------------------------------------------------------
module "autoscaling_group" {
  source = "../../atoms/ec2/autoscaling-group"

  config = {
    name                = var.config.name
    launch_template_id  = module.launch_template.manifest.id
    vpc_zone_identifier = var.config.subnet_ids

    min_size         = var.config.min_size
    max_size         = var.config.max_size
    desired_capacity = var.config.desired_capacity

    health_check_type = local.health_check_type
    target_group_arns = var.config.target_group_arns

    tags = local.tags
  }
}
