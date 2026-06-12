locals {
  module_tags = {
    Module = "atoms/cloudwatch/cloudwatch-metric-alarm" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.config.alarm_name
  comparison_operator = var.config.comparison_operator
  evaluation_periods  = var.config.evaluation_periods

  metric_name = var.config.metric_name
  namespace   = var.config.namespace
  period      = var.config.period
  statistic   = var.config.statistic
  threshold   = var.config.threshold

  alarm_actions = var.config.alarm_actions
  ok_actions    = var.config.ok_actions

  alarm_description   = var.config.alarm_description
  dimensions          = var.config.dimensions
  treat_missing_data  = var.config.treat_missing_data
  datapoints_to_alarm = var.config.datapoints_to_alarm

  tags = local.tags
}
