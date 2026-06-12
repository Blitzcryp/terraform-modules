locals {
  module_tags = {
    Module = "atoms/apigateway/apigatewayv2-stage" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  has_access_logs = var.config.access_log_destination_arn != null

  # Structured JSON access-log format capturing the fields PCI DSS Req 10 wants
  # for each request: who, when, what, from where, and the outcome.
  access_log_format = jsonencode({
    requestId               = "$context.requestId"
    ip                      = "$context.identity.sourceIp"
    requestTime             = "$context.requestTime"
    httpMethod              = "$context.httpMethod"
    routeKey                = "$context.routeKey"
    path                    = "$context.path"
    status                  = "$context.status"
    protocol                = "$context.protocol"
    responseLength          = "$context.responseLength"
    integrationErrorMessage = "$context.integrationErrorMessage"
  })
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = var.config.api_id
  name        = var.config.name
  auto_deploy = var.config.auto_deploy

  dynamic "access_log_settings" {
    for_each = local.has_access_logs ? [1] : []
    content {
      destination_arn = var.config.access_log_destination_arn
      format          = local.access_log_format
    }
  }

  default_route_settings {
    throttling_burst_limit = var.config.throttling_burst_limit
    throttling_rate_limit  = var.config.throttling_rate_limit
  }

  tags = local.tags

  # Access logging must be intentional to omit (PCI DSS Req 10).
  lifecycle {
    precondition {
      condition     = local.has_access_logs || var.config.allow_no_access_logs
      error_message = "Stage has no access_log_destination_arn and access logging is required (PCI DSS Req 10). Supply a CloudWatch log group ARN, or file a PCI exception (security@emag.ro) and set config.allow_no_access_logs=true."
    }
  }
}
