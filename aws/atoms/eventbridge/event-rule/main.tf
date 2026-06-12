locals {
  module_tags = {
    Module = "atoms/eventbridge/event-rule" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cloudwatch_event_rule" "this" {
  name                = var.config.name
  description         = var.config.description
  event_pattern       = var.config.event_pattern
  schedule_expression = var.config.schedule_expression
  state               = var.config.state
  event_bus_name      = var.config.event_bus_name

  tags = local.tags
}
