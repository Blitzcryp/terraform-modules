# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. ARNs/ids are unknown under the mock provider, so
# assertions target known/derived values.

mock_provider "aws" {}

run "target_defaults" {
  command = plan

  variables {
    config = {
      rule = "test-securityhub-findings"
      arn  = "arn:aws:sns:eu-central-1:111122223333:test-findings"
    }
  }

  assert {
    condition     = aws_cloudwatch_event_target.this.rule == "test-securityhub-findings"
    error_message = "Target must reference the requested rule."
  }

  assert {
    condition     = aws_cloudwatch_event_target.this.arn == "arn:aws:sns:eu-central-1:111122223333:test-findings"
    error_message = "Target must point at the requested destination ARN."
  }
}

# --- Negative: a non-ARN destination -> validation failure. ---
run "invalid_arn_is_rejected" {
  command = plan

  variables {
    config = {
      rule = "test-rule"
      arn  = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# --- Negative: both input and input_path set -> validation failure. ---
run "both_input_and_input_path_is_rejected" {
  command = plan

  variables {
    config = {
      rule       = "test-rule"
      arn        = "arn:aws:sns:eu-central-1:111122223333:test-findings"
      input      = "{\"hello\":\"world\"}"
      input_path = "$.detail"
    }
  }

  expect_failures = [
    var.config,
  ]
}
