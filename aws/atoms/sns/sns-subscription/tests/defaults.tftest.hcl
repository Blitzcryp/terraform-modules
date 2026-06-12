# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's defaults and input validation.

mock_provider "aws" {}

run "defaults_bind_subscription_to_topic" {
  command = plan

  variables {
    config = {
      topic_arn = "arn:aws:sns:eu-central-1:111122223333:test-events"
      protocol  = "sqs"
      endpoint  = "arn:aws:sqs:eu-central-1:111122223333:test-queue"
    }
  }

  assert {
    condition     = aws_sns_topic_subscription.this.topic_arn == "arn:aws:sns:eu-central-1:111122223333:test-events"
    error_message = "Subscription must bind to the supplied topic ARN."
  }

  assert {
    condition     = aws_sns_topic_subscription.this.protocol == "sqs"
    error_message = "Subscription protocol must be the supplied value."
  }

  # Conservative defaults: raw delivery off, no auto-confirm.
  assert {
    condition     = aws_sns_topic_subscription.this.raw_message_delivery == false
    error_message = "raw_message_delivery must default to false."
  }

  assert {
    condition     = aws_sns_topic_subscription.this.endpoint_auto_confirms == false
    error_message = "endpoint_auto_confirms must default to false."
  }
}

# --- Negative case: an unsupported protocol is rejected by config validation. ---
run "invalid_protocol_is_rejected" {
  command = plan

  variables {
    config = {
      topic_arn = "arn:aws:sns:eu-central-1:111122223333:test-events"
      protocol  = "carrier-pigeon"
      endpoint  = "somewhere"
    }
  }

  expect_failures = [
    var.config,
  ]
}
