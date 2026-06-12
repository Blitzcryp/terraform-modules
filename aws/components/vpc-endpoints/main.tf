data "aws_region" "current" {}

# Look up the VPC so we can default the endpoint SG ingress to the VPC's own
# CIDR — only in-VPC traffic may reach the endpoints (PCI DSS Req 1).
data "aws_vpc" "this" {
  id = var.config.vpc_id
}

locals {
  module_tags = {
    Module = "components/vpc-endpoints" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  region = data.aws_region.current.name

  # CIDRs allowed to reach the Interface endpoint ENIs on 443. Default to the
  # VPC's own CIDR when the caller supplies none.
  allowed_cidrs = length(var.config.allowed_cidrs) > 0 ? var.config.allowed_cidrs : [data.aws_vpc.this.cidr_block]

  # One documented 443 ingress rule per allowed CIDR.
  endpoint_ingress_rules = [
    for cidr in local.allowed_cidrs : {
      description = "HTTPS to VPC interface endpoints from ${cidr}"
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = cidr
    }
  ]

  # Build full service names: com.amazonaws.<region>.<short>.
  gateway_endpoints = {
    for short in var.config.gateway_services :
    short => "com.amazonaws.${local.region}.${short}"
  }
  interface_endpoints = {
    for short in var.config.interface_services :
    short => "com.amazonaws.${local.region}.${short}"
  }
}

# --- Endpoint security group -------------------------------------------------
# Guards the Interface endpoint ENIs: only 443 from the allowed CIDRs in, and
# (deliberately) no egress rules — the endpoint only ever responds to inbound
# requests it has accepted, so it needs no outbound openings.
module "endpoint_sg" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "vpc-endpoints-"
    vpc_id        = var.config.vpc_id
    description   = "HTTPS access to VPC interface endpoints"
    ingress_rules = local.endpoint_ingress_rules
    tags          = var.config.tags
  }
}

# --- Gateway endpoints (S3, DynamoDB) ----------------------------------------
# Attach to the private route tables; no ENI, no SG, no private DNS.
module "gateway_endpoint" {
  source   = "../../atoms/vpc/vpc-endpoint"
  for_each = local.gateway_endpoints

  config = {
    vpc_id            = var.config.vpc_id
    service_name      = each.value
    vpc_endpoint_type = "Gateway"
    route_table_ids   = var.config.private_route_table_ids
    tags              = var.config.tags
  }
}

# --- Interface endpoints (ECR, Logs, Secrets Manager, KMS, SSM, STS, …) ------
# ENIs in the private subnets, guarded by the endpoint SG, with private DNS ON
# so the standard service hostnames resolve privately (PCI DSS Req 1).
module "interface_endpoint" {
  source   = "../../atoms/vpc/vpc-endpoint"
  for_each = local.interface_endpoints

  config = {
    vpc_id              = var.config.vpc_id
    service_name        = each.value
    vpc_endpoint_type   = "Interface"
    subnet_ids          = var.config.private_subnet_ids
    security_group_ids  = [module.endpoint_sg.manifest.id]
    private_dns_enabled = true
    tags                = var.config.tags
  }
}
