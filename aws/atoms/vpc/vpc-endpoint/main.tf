locals {
  module_tags = {
    Module = "atoms/vpc/vpc-endpoint" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  is_interface = var.config.vpc_endpoint_type == "Interface"

  # private_dns_enabled is only meaningful for Interface endpoints; AWS rejects
  # it (true) on Gateway/GatewayLoadBalancer endpoints. Force null off-Interface.
  private_dns_enabled = local.is_interface ? var.config.private_dns_enabled : null

  # Empty lists become null so the provider treats them as unset rather than
  # an explicit empty assignment.
  subnet_ids         = length(var.config.subnet_ids) > 0 ? var.config.subnet_ids : null
  security_group_ids = length(var.config.security_group_ids) > 0 ? var.config.security_group_ids : null
  route_table_ids    = length(var.config.route_table_ids) > 0 ? var.config.route_table_ids : null
}

resource "aws_vpc_endpoint" "this" {
  vpc_id            = var.config.vpc_id
  service_name      = var.config.service_name
  vpc_endpoint_type = var.config.vpc_endpoint_type

  subnet_ids          = local.subnet_ids
  security_group_ids  = local.security_group_ids
  route_table_ids     = local.route_table_ids
  private_dns_enabled = local.private_dns_enabled

  policy = var.config.policy

  tags = local.tags

  lifecycle {
    # An Interface endpoint with no security groups is exposed to anything that
    # can route to its ENIs. Require SGs so 443 ingress is explicitly scoped
    # (PCI DSS Req 1 — only documented, necessary traffic is permitted).
    precondition {
      condition     = !local.is_interface || length(var.config.security_group_ids) > 0
      error_message = "An Interface endpoint requires config.security_group_ids so access to its ENIs is explicitly scoped (PCI DSS Req 1)."
    }

    # A Gateway endpoint that attaches to no route table installs no route and
    # silently does nothing — guard against the misconfiguration.
    precondition {
      condition     = local.is_interface || length(var.config.route_table_ids) > 0
      error_message = "A Gateway endpoint requires config.route_table_ids so the service prefix-list route is actually installed."
    }
  }
}
