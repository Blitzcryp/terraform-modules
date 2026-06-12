# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's default behaviour. ARNs are unknown
# under the mock provider, so assertions target known/derived values.

mock_provider "aws" {}

run "pattern_rule_defaults" {
  command = plan

  variables {
    config = {
      name = "test-securityhub-findings"
      event_pattern = jsonencode({
        source      = ["aws.securityhub"]
        detail-type = ["Security Hub Findings - Imported"]
      })
    }
  }

  assert {
    condition     = aws_cloudwatch_event_rule.this.state == "ENABLED"
    error_message = "Rule must default to ENABLED."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.this.name == "test-securityhub-findings"
    error_message = "Rule must be planned with the requested name."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.this.schedule_expression == null
    error_message = "schedule_expression must be unset for a pattern rule."
  }
}

run "schedule_rule_is_accepted" {
  command = plan

  variables {
    config = {
      name                = "test-nightly"
      schedule_expression = "rate(1 day)"
    }
  }

  assert {
    condition     = aws_cloudwatch_event_rule.this.schedule_expression == "rate(1 day)"
    error_message = "Schedule expression must be passed through."
  }
}

# --- Negative: neither pattern nor schedule -> validation failure. ---
run "neither_pattern_nor_schedule_is_rejected" {
  command = plan

  variables {
    config = {
      name = "test-empty"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# --- Negative: both pattern and schedule -> validation failure. ---
run "both_pattern_and_schedule_is_rejected" {
  command = plan

  variables {
    config = {
      name                = "test-both"
      event_pattern       = "{\"source\":[\"aws.securityhub\"]}"
      schedule_expression = "rate(1 day)"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# --- Negative: invalid state value -> validation failure. ---
run "invalid_state_is_rejected" {
  command = plan

  variables {
    config = {
      name          = "test-state"
      event_pattern = "{\"source\":[\"aws.securityhub\"]}"
      state         = "PAUSED"
    }
  }

  expect_failures = [
    var.config,
  ]
}
