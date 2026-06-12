# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Computed ids are unknown under the mock, so we assert on
# known/derived values (echoed statement_id, default action) and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      function_name = "test-fn"
      statement_id  = "AllowEventBridgeInvoke"
      principal     = "events.amazonaws.com"
      source_arn    = "arn:aws:events:eu-central-1:111122223333:rule/test-rule"
    }
  }

  # Narrowest useful action by default.
  assert {
    condition     = aws_lambda_permission.this.action == "lambda:InvokeFunction"
    error_message = "action must default to lambda:InvokeFunction."
  }

  assert {
    condition     = aws_lambda_permission.this.statement_id == "AllowEventBridgeInvoke"
    error_message = "statement_id must be echoed to the resource."
  }

  # source_arn threaded through to scope the grant.
  assert {
    condition     = aws_lambda_permission.this.source_arn == "arn:aws:events:eu-central-1:111122223333:rule/test-rule"
    error_message = "source_arn must scope the permission."
  }
}

run "invalid_statement_id_is_rejected" {
  command = plan

  variables {
    config = {
      function_name = "test-fn"
      statement_id  = "not valid id!"
      principal     = "events.amazonaws.com"
    }
  }

  expect_failures = [
    var.config,
  ]
}
