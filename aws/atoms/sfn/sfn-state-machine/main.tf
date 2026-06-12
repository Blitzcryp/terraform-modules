locals {
  module_tags = {
    Module = "atoms/sfn/sfn-state-machine" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Logging is active unless the caller explicitly chose OFF. Active logging
  # requires a CloudWatch Logs destination (PCI DSS Req 10).
  logging_enabled = var.config.log_level != "OFF"

  # CloudWatch Logs delivery for Step Functions targets the log group's streams,
  # so the destination ARN carries the ':*' suffix on the log group ARN.
  log_destination = (
    local.logging_enabled && var.config.log_destination_arn != null
    ? "${var.config.log_destination_arn}:*"
    : null
  )
}

resource "aws_sfn_state_machine" "this" {
  name       = var.config.name
  definition = var.config.definition
  role_arn   = var.config.role_arn
  type       = var.config.type

  # Execution logging (PCI DSS Req 10). When the caller selects OFF, the AWS API
  # requires no log_destination; otherwise we wire the CloudWatch log group.
  logging_configuration {
    level                  = var.config.log_level
    include_execution_data = var.config.include_execution_data
    log_destination        = local.log_destination
  }

  # X-Ray distributed tracing (PCI DSS Req 10 observability).
  tracing_configuration {
    enabled = var.config.enable_tracing
  }

  tags = local.tags

  lifecycle {
    # Execution logging must be intentional to disable (PCI DSS Req 10). Logging
    # can only be active with a CloudWatch destination; running without one (no
    # destination, or level OFF) requires config.allow_no_logging=true.
    precondition {
      condition     = (local.logging_enabled && var.config.log_destination_arn != null) || var.config.allow_no_logging
      error_message = "State machine has no execution logging (no log_destination_arn, or log_level=OFF) without config.allow_no_logging=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
