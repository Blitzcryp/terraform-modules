locals {
  module_tags = {
    Module = "atoms/apigateway/apigatewayv2-route" # only hardcoded tag; global tags come from provider default_tags
  }
  # NOTE: aws_apigatewayv2_route does not support tags. local.tags is retained
  # for convention/consistency but is intentionally not attached to the resource.
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_apigatewayv2_route" "this" {
  api_id    = var.config.api_id
  route_key = var.config.route_key
  target    = var.config.target

  authorization_type = var.config.authorization_type
  authorizer_id      = var.config.authorizer_id
}
