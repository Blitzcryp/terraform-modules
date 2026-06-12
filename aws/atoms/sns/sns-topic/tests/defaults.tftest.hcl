# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

# The SNS topic policy validates that its `arn` is a real ARN, so the mocked
# topic must return a syntactically valid ARN rather than a random string.
mock_provider "aws" {
  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:eu-central-1:111122223333:test-events"
    }
  }
}

run "secure_defaults" {
  # apply: the topic policy is computed from the (mocked) topic ARN, so its
  # content is only known after apply — the mock provider supplies fake values.
  command = apply

  variables {
    config = {
      name        = "test-events"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # PCI DSS Req 3: encryption at rest is configured from the CMK ARN.
  assert {
    condition     = aws_sns_topic.this.kms_master_key_id == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "Topic must use the supplied CMK for encryption at rest (PCI DSS Req 3)."
  }

  # PCI DSS Req 4: the attached policy denies non-TLS publish.
  assert {
    condition     = strcontains(aws_sns_topic_policy.this.policy, "aws:SecureTransport")
    error_message = "Topic policy must deny non-TLS publish (PCI DSS Req 4)."
  }

  assert {
    condition     = strcontains(aws_sns_topic_policy.this.policy, "DenyPublishOverNonTLS")
    error_message = "Topic policy must contain the TLS-deny statement."
  }
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name = "test-events"
      # kms_key_arn omitted (null) and allow_unencrypted left at its false default
    }
  }

  expect_failures = [
    aws_sns_topic.this,
  ]
}

run "fifo_name_validation_rejects_missing_suffix" {
  command = plan

  variables {
    config = {
      name        = "test-events" # missing required '.fifo' suffix
      fifo_topic  = true
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  expect_failures = [
    var.config,
  ]
}
