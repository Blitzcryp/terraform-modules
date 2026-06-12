# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Computed ARNs/IDs are unknown under the mock, so we
# assert on known/derived values and on plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-http-api"
    }
  }

  assert {
    condition     = aws_apigatewayv2_api.this.protocol_type == "HTTP"
    error_message = "protocol_type must default to HTTP."
  }

  assert {
    condition     = aws_apigatewayv2_api.this.disable_execute_api_endpoint == false
    error_message = "disable_execute_api_endpoint must default to false."
  }

  assert {
    condition     = aws_apigatewayv2_api.this.name == "test-http-api"
    error_message = "API name must equal config.name."
  }
}

run "cors_configuration_is_applied_when_set" {
  command = plan

  variables {
    config = {
      name = "test-http-api"
      cors_configuration = {
        allow_origins = ["https://app.example.com"]
        allow_methods = ["GET", "POST"]
      }
    }
  }

  assert {
    condition     = length(aws_apigatewayv2_api.this.cors_configuration) == 1
    error_message = "cors_configuration block must be created when config.cors_configuration is set."
  }
}

run "invalid_protocol_type_is_rejected" {
  command = plan

  variables {
    config = {
      name          = "test-http-api"
      protocol_type = "GRPC"
    }
  }

  expect_failures = [
    var.config,
  ]
}
