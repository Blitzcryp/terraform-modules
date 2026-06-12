locals {
  module_tags = {
    Module = "atoms/apigateway/apigatewayv2-integration" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_apigatewayv2_integration" "this" {
  api_id           = var.config.api_id
  integration_type = var.config.integration_type
  integration_uri  = var.config.integration_uri

  # integration_method only applies to integrations that call a backend
  # (AWS / AWS_PROXY / HTTP / HTTP_PROXY); MOCK has no backend method.
  integration_method = var.config.integration_type == "MOCK" ? null : var.config.integration_method

  payload_format_version = var.config.payload_format_version
  connection_type        = var.config.connection_type
}
