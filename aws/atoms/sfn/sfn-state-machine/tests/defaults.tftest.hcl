# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the module's secure-by-default behaviour.
# Computed ARNs are unknown under the mock, so we assert on known/derived values
# (logging level, tracing flag, derived log_destination) and on plan success.

mock_provider "aws" {}

variables {
  base = {
    name                = "test-workflow"
    role_arn            = "arn:aws:iam::111122223333:role/test-sfn-role"
    definition          = "{\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Pass\",\"End\":true}}}"
    log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/vendedlogs/states/test-workflow"
  }
}

run "secure_defaults" {
  command = plan

  variables {
    config = var.base
  }

  # Execution logging defaults to ALL (PCI DSS Req 10).
  assert {
    condition     = aws_sfn_state_machine.this.logging_configuration[0].level == "ALL"
    error_message = "Logging level must default to ALL (PCI DSS Req 10)."
  }

  # Execution data must NOT be logged by default (PCI DSS Req 3: avoid CHD).
  assert {
    condition     = aws_sfn_state_machine.this.logging_configuration[0].include_execution_data == false
    error_message = "include_execution_data must default to false (avoid logging CHD payloads)."
  }

  # The log destination is the log group ARN with the ':*' stream suffix.
  assert {
    condition     = aws_sfn_state_machine.this.logging_configuration[0].log_destination == "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/vendedlogs/states/test-workflow:*"
    error_message = "log_destination must be the log group ARN with a ':*' suffix."
  }

  # X-Ray tracing on by default.
  assert {
    condition     = aws_sfn_state_machine.this.tracing_configuration[0].enabled == true
    error_message = "X-Ray tracing must default to enabled (PCI DSS Req 10)."
  }

  # STANDARD type by default.
  assert {
    condition     = aws_sfn_state_machine.this.type == "STANDARD"
    error_message = "State machine type must default to STANDARD."
  }
}

run "no_logging_without_escape_hatch_is_blocked" {
  command = plan

  variables {
    config = {
      name       = "test-workflow"
      role_arn   = "arn:aws:iam::111122223333:role/test-sfn-role"
      definition = "{\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Pass\",\"End\":true}}}"
      # no log_destination_arn and allow_no_logging left at its false default
    }
  }

  expect_failures = [
    aws_sfn_state_machine.this,
  ]
}

run "no_logging_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name             = "test-workflow"
      role_arn         = "arn:aws:iam::111122223333:role/test-sfn-role"
      definition       = "{\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Pass\",\"End\":true}}}"
      log_level        = "OFF"
      allow_no_logging = true
    }
  }

  assert {
    condition     = aws_sfn_state_machine.this.logging_configuration[0].log_destination == null
    error_message = "log_destination must be null when logging is OFF."
  }
}

run "invalid_type_is_rejected" {
  command = plan

  variables {
    config = {
      name                = "test-workflow"
      role_arn            = "arn:aws:iam::111122223333:role/test-sfn-role"
      definition          = "{\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Pass\",\"End\":true}}}"
      log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/vendedlogs/states/test-workflow"
      type                = "TURBO"
    }
  }

  expect_failures = [
    var.config,
  ]
}
