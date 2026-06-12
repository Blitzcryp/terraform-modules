locals {
  module_tags = {
    Module = "atoms/route53/route53-zone" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Query logging is only supported on PUBLIC hosted zones. For private zones
  # we skip the query-log resource (and the precondition) entirely.
  query_logging_enabled = !var.config.private_zone && var.config.query_log_destination_arn != null
}

resource "aws_route53_zone" "this" {
  name          = var.config.name
  comment       = var.config.comment
  force_destroy = var.config.force_destroy

  # A private zone is defined by the presence of vpc associations.
  dynamic "vpc" {
    for_each = var.config.private_zone ? toset(var.config.vpc_ids) : toset([])
    content {
      vpc_id = vpc.value
    }
  }

  tags = local.tags

  # DNS query logging must be intentional to weaken on public zones (PCI DSS
  # Req 10). Private zones do not support query logging, so the control is N/A.
  lifecycle {
    precondition {
      condition = (
        var.config.private_zone ||
        local.query_logging_enabled ||
        var.config.allow_query_logging_disabled
      )
      error_message = "Public zone query logging disabled without config.allow_query_logging_disabled=true. Set config.query_log_destination_arn (a us-east-1 CloudWatch Logs group ARN) or file a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Tightly-coupled sub-resource: DNS query logging for the public zone.
resource "aws_route53_query_log" "this" {
  count                    = local.query_logging_enabled ? 1 : 0
  zone_id                  = aws_route53_zone.this.zone_id
  cloudwatch_log_group_arn = var.config.query_log_destination_arn
}
