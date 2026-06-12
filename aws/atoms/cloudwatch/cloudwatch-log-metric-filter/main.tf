locals {
  module_tags = {
    Module = "atoms/cloudwatch/cloudwatch-log-metric-filter" # only hardcoded tag; global tags come from provider default_tags
  }
  # NOTE: aws_cloudwatch_log_metric_filter is NOT taggable. We compute the merged
  # tag set for interface uniformity but the resource does not accept a `tags` arg.
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  name           = var.config.name
  log_group_name = var.config.log_group_name
  pattern        = var.config.pattern

  metric_transformation {
    name          = var.config.metric_name
    namespace     = var.config.metric_namespace
    value         = var.config.metric_value
    default_value = var.config.default_value
  }
}
