locals {
  module_tags = {
    Module = "atoms/vpc/route-table" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  name_tag = var.config.name == null ? {} : { Name = var.config.name }

  # Routes are keyed by their (static) destination CIDR so adding/removing one
  # entry does not churn the others.
  routes = { for r in var.config.routes : r.cidr_block => r }
}

resource "aws_route_table" "this" {
  vpc_id = var.config.vpc_id

  tags = merge(local.tags, local.name_tag)
}

# Tightly-coupled: routes belong to exactly this table. The config validation
# guarantees each route has exactly one target.
resource "aws_route" "this" {
  for_each = local.routes

  route_table_id         = aws_route_table.this.id
  destination_cidr_block = each.value.cidr_block
  gateway_id             = each.value.gateway_id
  nat_gateway_id         = each.value.nat_gateway_id
  vpc_endpoint_id        = each.value.vpc_endpoint_id
}

# Tightly-coupled: associate this table with each supplied subnet. Indexed by
# position (count) rather than for_each, because subnet ids are frequently
# apply-unknown (e.g. created by a sibling module in the same plan) and cannot
# be used as for_each keys. The input list order is stable.
resource "aws_route_table_association" "this" {
  count = length(var.config.subnet_ids)

  route_table_id = aws_route_table.this.id
  subnet_id      = var.config.subnet_ids[count.index]
}
