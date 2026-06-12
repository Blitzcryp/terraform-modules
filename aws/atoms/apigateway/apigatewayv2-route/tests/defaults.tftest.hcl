# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      api_id    = "abcd1234ef"
      route_key = "GET /items"
      target    = "integrations/xyz789"
    }
  }

  assert {
    condition     = aws_apigatewayv2_route.this.route_key == "GET /items"
    error_message = "route_key must equal config.route_key."
  }

  assert {
    condition     = aws_apigatewayv2_route.this.authorization_type == "NONE"
    error_message = "authorization_type must default to NONE."
  }

  assert {
    condition     = aws_apigatewayv2_route.this.target == "integrations/xyz789"
    error_message = "target must equal config.target."
  }
}

run "invalid_authorization_type_is_rejected" {
  command = plan

  variables {
    config = {
      api_id             = "abcd1234ef"
      route_key          = "GET /items"
      authorization_type = "BASIC"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative case (validation): JWT authorization requires an authorizer_id.
run "jwt_without_authorizer_id_is_rejected" {
  command = plan

  variables {
    config = {
      api_id             = "abcd1234ef"
      route_key          = "GET /items"
      authorization_type = "JWT"
      # authorizer_id omitted
    }
  }

  expect_failures = [
    var.config,
  ]
}
