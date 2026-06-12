# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      api_id          = "abcd1234ef"
      integration_uri = "arn:aws:lambda:eu-central-1:111122223333:function:test-fn"
    }
  }

  assert {
    condition     = aws_apigatewayv2_integration.this.integration_type == "AWS_PROXY"
    error_message = "integration_type must default to AWS_PROXY."
  }

  assert {
    condition     = aws_apigatewayv2_integration.this.integration_method == "POST"
    error_message = "integration_method must default to POST."
  }

  assert {
    condition     = aws_apigatewayv2_integration.this.payload_format_version == "2.0"
    error_message = "payload_format_version must default to 2.0."
  }

  assert {
    condition     = aws_apigatewayv2_integration.this.connection_type == "INTERNET"
    error_message = "connection_type must default to INTERNET."
  }
}

run "invalid_integration_type_is_rejected" {
  command = plan

  variables {
    config = {
      api_id           = "abcd1234ef"
      integration_type = "LAMBDA"
    }
  }

  expect_failures = [
    var.config,
  ]
}
