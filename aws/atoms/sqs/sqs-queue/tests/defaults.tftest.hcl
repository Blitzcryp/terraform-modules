# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults_with_cmk" {
  # apply: redrive_policy and the queue policy are computed from (mocked) ARNs,
  # so their content is only known after apply — the mock provider fills these.
  command = apply

  variables {
    config = {
      name        = "test-jobs"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # PCI DSS Req 3: encryption at rest uses the supplied CMK.
  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "Queue must use the supplied CMK for encryption at rest (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_sqs_queue.this.message_retention_seconds == 345600
    error_message = "Message retention must default to 345600 seconds (4 days)."
  }

  # DLQ created by default and wired into the redrive policy.
  assert {
    condition     = length(aws_sqs_queue.dlq) == 1
    error_message = "A dead-letter queue must be created by default."
  }

  assert {
    condition     = strcontains(aws_sqs_queue.this.redrive_policy, "deadLetterTargetArn")
    error_message = "The main queue must reference the DLQ via redrive_policy."
  }

  # PCI DSS Req 4: the attached policy denies non-TLS access.
  assert {
    condition     = strcontains(aws_sqs_queue_policy.this.policy, "aws:SecureTransport")
    error_message = "Queue policy must deny non-TLS access (PCI DSS Req 4)."
  }

  assert {
    condition     = strcontains(aws_sqs_queue_policy.this.policy, "DenyAccessOverNonTLS")
    error_message = "Queue policy must contain the TLS-deny statement."
  }
}

run "sse_sqs_fallback_when_no_cmk" {
  command = plan

  variables {
    config = {
      name = "test-jobs"
      # no kms_key_arn — encryption must fall back to SSE-SQS, never off.
    }
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled == true
    error_message = "Without a CMK, SSE-SQS must be enabled so the queue is never unencrypted (PCI DSS Req 3)."
  }
}

run "cmk_takes_precedence_over_sse_sqs" {
  command = plan

  variables {
    config = {
      name        = "test-jobs"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # When a CMK is supplied it is used for encryption and SSE-SQS is NOT also
  # toggled on (the two SSE modes are mutually exclusive — it is left unset).
  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled != true
    error_message = "When a CMK is present, SSE-SQS should not also be toggled on."
  }
}

run "fifo_name_validation_rejects_missing_suffix" {
  command = plan

  variables {
    config = {
      name        = "test-jobs" # missing required '.fifo' suffix
      fifo_queue  = true
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "retention_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      name                      = "test-jobs"
      kms_key_arn               = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      message_retention_seconds = 10 # below the 60s floor
    }
  }

  expect_failures = [
    var.config,
  ]
}
