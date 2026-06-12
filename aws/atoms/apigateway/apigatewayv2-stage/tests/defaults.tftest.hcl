# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults_with_access_logs" {
  command = plan

  variables {
    config = {
      api_id                     = "abcd1234ef"
      access_log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/apigateway/test:*"
    }
  }

  assert {
    condition     = aws_apigatewayv2_stage.this.name == "$default"
    error_message = "Stage name must default to $default."
  }

  assert {
    condition     = aws_apigatewayv2_stage.this.auto_deploy == true
    error_message = "auto_deploy must default to true."
  }

  # Access logging wired (PCI DSS Req 10).
  assert {
    condition     = length(aws_apigatewayv2_stage.this.access_log_settings) == 1
    error_message = "Access logging must be wired when a destination ARN is supplied."
  }

  # Throttling on by default.
  assert {
    condition     = aws_apigatewayv2_stage.this.default_route_settings[0].throttling_burst_limit == 5000
    error_message = "Default throttling burst limit must be 5000."
  }

  assert {
    condition     = aws_apigatewayv2_stage.this.default_route_settings[0].throttling_rate_limit == 10000
    error_message = "Default throttling rate limit must be 10000."
  }
}

run "no_access_logs_with_escape_hatch_succeeds" {
  command = plan

  variables {
    config = {
      api_id               = "abcd1234ef"
      allow_no_access_logs = true
    }
  }

  assert {
    condition     = length(aws_apigatewayv2_stage.this.access_log_settings) == 0
    error_message = "No access_log_settings block must be created when no destination is supplied."
  }
}

# Negative case (precondition): no access log destination and no escape hatch.
run "no_access_logs_without_escape_hatch_is_blocked" {
  command = plan

  variables {
    config = {
      api_id = "abcd1234ef"
      # access_log_destination_arn omitted, allow_no_access_logs left false
    }
  }

  expect_failures = [
    aws_apigatewayv2_stage.this,
  ]
}
