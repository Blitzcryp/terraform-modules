locals {
  # NOTE: aws_cloudwatch_event_target has no tags argument, so module_tags/tags
  # cannot be applied. We keep the merge for parity and reference it to avoid an
  # unused-local lint, but it is intentionally not wired to any resource.
  module_tags = {
    Module = "atoms/eventbridge/event-target"
  }
  tags = merge(local.module_tags, var.config.tags) # no-op: resource has no tags
}

resource "aws_cloudwatch_event_target" "this" {
  rule           = var.config.rule
  arn            = var.config.arn
  target_id      = var.config.target_id
  event_bus_name = var.config.event_bus_name
  role_arn       = var.config.role_arn
  input          = var.config.input
  input_path     = var.config.input_path
}
