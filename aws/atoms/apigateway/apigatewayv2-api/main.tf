locals {
  module_tags = {
    Module = "atoms/apigateway/apigatewayv2-api" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_apigatewayv2_api" "this" {
  name                         = var.config.name
  protocol_type                = var.config.protocol_type
  disable_execute_api_endpoint = var.config.disable_execute_api_endpoint

  dynamic "cors_configuration" {
    for_each = var.config.cors_configuration == null ? [] : [var.config.cors_configuration]
    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
    }
  }

  tags = local.tags
}
