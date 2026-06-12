data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/secure-network" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # A caller-supplied (BYO) flow-log sink is used only when BOTH the
  # destination ARN and the delivery role ARN are provided. The variable
  # validation guarantees they arrive together.
  use_byo_flow_logs = var.config.byo_flow_log_destination_arn != null && var.config.byo_flow_log_role_arn != null

  # Self-provision the kms/log-group/iam-role trio only when flow logs are
  # enabled and the caller did not bring their own sink.
  self_provision_flow_logs = var.config.enable_flow_logs && !local.use_byo_flow_logs

  # Map subnet name => subnet object for a stable for_each key.
  subnets = { for s in var.config.subnets : s.name => s }

  # --- Routing topology --------------------------------------------------------
  public_subnets  = [for s in var.config.subnets : s if s.public]
  private_subnets = [for s in var.config.subnets : s if !s.public]
  has_public      = length(local.public_subnets) > 0

  # Internet gateway: explicit override, else auto (on iff any public subnet).
  create_igw = var.config.enable_internet_gateway != null ? var.config.enable_internet_gateway : local.has_public

  # NAT gateways are placed in public subnets, one per "nat key":
  #   single => a single NAT keyed by the first public subnet's AZ
  #   per_az => one NAT per distinct AZ that has a public subnet
  #   none   => no NAT
  public_azs = distinct([for s in local.public_subnets : s.availability_zone])

  # First public subnet per AZ (stable: ordered by config list) → NAT host.
  public_subnet_by_az = {
    for az in local.public_azs :
    az => [for s in local.public_subnets : s if s.availability_zone == az][0]
  }

  nat_azs = (
    var.config.nat_gateway_mode == "none" || !local.has_public ? [] :
    var.config.nat_gateway_mode == "single" ? [local.public_azs[0]] :
    local.public_azs # per_az
  )
  # nat key (AZ) => the public subnet object that will host the NAT.
  nat_hosts = { for az in local.nat_azs : az => local.public_subnet_by_az[az] }

  # Which NAT AZ serves a given private subnet:
  #   single => the one-and-only NAT
  #   per_az => the NAT in the subnet's own AZ if present, else the first NAT
  nat_for_private_az = {
    for az in distinct([for s in local.private_subnets : s.availability_zone]) :
    az => (
      var.config.nat_gateway_mode == "single" ? local.nat_azs[0] :
      contains(local.nat_azs, az) ? az : local.nat_azs[0]
    ) if length(local.nat_azs) > 0
  }

  # Private route tables: one shared table for "single"/"none", one per AZ for
  # "per_az" (so each AZ routes to its own NAT). Keyed for stable for_each.
  private_rt_keys = (
    length(local.private_subnets) == 0 ? [] :
    var.config.nat_gateway_mode == "per_az" ?
    distinct([for s in local.private_subnets : s.availability_zone]) :
    ["shared"]
  )

  # Map each private route-table key => its NAT AZ (null when no NAT exists).
  private_rt_nat_az = {
    for k in local.private_rt_keys :
    k => (
      length(local.nat_azs) == 0 ? null :
      k == "shared" ? local.nat_azs[0] : lookup(local.nat_for_private_az, k, local.nat_azs[0])
    )
  }

  # Subnet ids grouped per private route-table key.
  private_subnet_ids_by_rt = {
    for k in local.private_rt_keys :
    k => [
      for s in local.private_subnets :
      module.subnet[s.name].manifest.id
      if(var.config.nat_gateway_mode == "per_az" ? s.availability_zone == k : true)
    ]
  }

  public_subnet_ids = [for s in local.public_subnets : module.subnet[s.name].manifest.id]

  # Final ARNs handed to the vpc atom: BYO, else self-provisioned, else null.
  flow_log_destination_arn = local.use_byo_flow_logs ? var.config.byo_flow_log_destination_arn : (
    local.self_provision_flow_logs ? module.flow_log_group[0].manifest.arn : null
  )
  flow_log_role_arn = local.use_byo_flow_logs ? var.config.byo_flow_log_role_arn : (
    local.self_provision_flow_logs ? module.flow_log_role[0].manifest.arn : null
  )

  # Predictable name for the self-provisioned flow-log group.
  flow_log_group_name = "/aws/vpc/flow-logs/${var.config.name}"

  # KMS key policy for the self-provisioned key. CloudWatch Logs encrypts log
  # data with this CMK, so the regional Logs service principal MUST be granted
  # crypto operations or the encrypted log group fails at apply time. Account
  # root retains administrative control.
  flow_log_kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogsEncryption"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.name}.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.flow_log_group_name}"
          }
        }
      },
    ]
  })

  # Trust policy: only the VPC Flow Logs service may assume the delivery role.
  flow_log_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "vpc-flow-logs.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  # Least-privilege inline policy: write VPC flow logs only to this log group.
  flow_log_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.flow_log_group_name}",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.flow_log_group_name}:*",
        ]
      }
    ]
  })
}

# --- Self-provisioned flow-log sink (kms + log group + delivery role) --------

module "flow_log_kms" {
  source = "../../atoms/kms/kms-key"
  count  = local.self_provision_flow_logs ? 1 : 0

  config = {
    description = "Encrypts VPC flow logs for ${var.config.name}"
    alias       = "vpc-flow-logs/${var.config.name}"
    policy      = local.flow_log_kms_policy
    tags        = local.tags
  }
}

module "flow_log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"
  count  = local.self_provision_flow_logs ? 1 : 0

  config = {
    name              = local.flow_log_group_name
    kms_key_arn       = module.flow_log_kms[0].manifest.arn
    retention_in_days = var.config.flow_log_retention_in_days
    tags              = local.tags
  }
}

module "flow_log_role" {
  source = "../../atoms/iam/iam-role"
  count  = local.self_provision_flow_logs ? 1 : 0

  config = {
    name_prefix        = "vpc-flow-logs-"
    description        = "VPC flow-logs delivery role for ${var.config.name}"
    assume_role_policy = local.flow_log_assume_role_policy
    inline_policies = {
      flow-logs-delivery = local.flow_log_inline_policy
    }
    tags = local.tags
  }
}

# --- VPC ---------------------------------------------------------------------

module "vpc" {
  source = "../../atoms/vpc/vpc"

  config = {
    name                     = var.config.name
    cidr_block               = var.config.cidr_block
    enable_flow_logs         = var.config.enable_flow_logs
    flow_log_destination_arn = local.flow_log_destination_arn
    flow_log_iam_role_arn    = local.flow_log_role_arn
    allow_flow_logs_disabled = var.config.allow_flow_logs_disabled
    tags                     = local.tags
  }
}

# --- Subnets -----------------------------------------------------------------

module "subnet" {
  source   = "../../atoms/vpc/subnet"
  for_each = local.subnets

  config = {
    name              = each.value.name
    vpc_id            = module.vpc.manifest.id
    cidr_block        = each.value.cidr_block
    availability_zone = each.value.availability_zone

    # A public subnet is an intentional choice: enable auto-assign public IPs
    # AND flip the subnet atom's escape hatch so the choice is auditable.
    # Private subnets (the default) leave both false.
    map_public_ip_on_launch = each.value.public
    allow_auto_public_ip    = each.value.public

    tags = local.tags
  }
}

# --- Internet gateway --------------------------------------------------------

module "internet_gateway" {
  source = "../../atoms/vpc/internet-gateway"
  count  = local.create_igw ? 1 : 0

  config = {
    vpc_id = module.vpc.manifest.id
    name   = "${var.config.name}-igw"
    tags   = local.tags
  }
}

# --- Elastic IPs + NAT gateways (one per nat AZ) -----------------------------

module "nat_eip" {
  source   = "../../atoms/vpc/elastic-ip"
  for_each = local.nat_hosts

  config = {
    name = "${var.config.name}-nat-${each.key}"
    tags = local.tags
  }
}

module "nat_gateway" {
  source   = "../../atoms/vpc/nat-gateway"
  for_each = local.nat_hosts

  config = {
    subnet_id     = module.subnet[each.value.name].manifest.id
    allocation_id = module.nat_eip[each.key].manifest.allocation_id
    name          = "${var.config.name}-nat-${each.key}"
    tags          = local.tags
  }
}

# --- Public route table (0.0.0.0/0 -> IGW) -----------------------------------

module "public_route_table" {
  source = "../../atoms/vpc/route-table"
  count  = local.has_public && local.create_igw ? 1 : 0

  config = {
    vpc_id = module.vpc.manifest.id
    name   = "${var.config.name}-public-rt"
    routes = [
      {
        cidr_block = "0.0.0.0/0"
        gateway_id = module.internet_gateway[0].manifest.id
      },
    ]
    subnet_ids = local.public_subnet_ids
    tags       = local.tags
  }
}

# --- Private route table(s) (0.0.0.0/0 -> NAT) -------------------------------
# One shared table for "single"/"none", one per AZ for "per_az". A default
# route is added only when a NAT exists for that table; with nat_gateway_mode
# "none" the private table has no egress route.

module "private_route_table" {
  source   = "../../atoms/vpc/route-table"
  for_each = toset(local.private_rt_keys)

  config = {
    vpc_id = module.vpc.manifest.id
    name   = "${var.config.name}-private-rt-${each.key}"
    routes = local.private_rt_nat_az[each.key] == null ? [] : [
      {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = module.nat_gateway[local.private_rt_nat_az[each.key]].manifest.id
      },
    ]
    subnet_ids = local.private_subnet_ids_by_rt[each.key]
    tags       = local.tags
  }
}
