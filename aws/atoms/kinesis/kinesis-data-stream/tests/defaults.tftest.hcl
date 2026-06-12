# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-events"
    }
  }

  assert {
    condition     = aws_kinesis_stream.this.encryption_type == "KMS"
    error_message = "Stream must default to KMS encryption (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_kinesis_stream.this.kms_key_id == "alias/aws/kinesis"
    error_message = "Without a BYO CMK, the AWS-managed kinesis key must be used."
  }

  assert {
    condition     = aws_kinesis_stream.this.stream_mode_details[0].stream_mode == "ON_DEMAND"
    error_message = "Stream must default to ON_DEMAND mode."
  }

  assert {
    condition     = aws_kinesis_stream.this.shard_count == null
    error_message = "ON_DEMAND streams must not set a shard_count."
  }

  assert {
    condition     = aws_kinesis_stream.this.retention_period == 24
    error_message = "Retention period must default to 24 hours."
  }
}

run "byo_key_is_used" {
  command = plan

  variables {
    config = {
      name        = "test-events-byo"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = aws_kinesis_stream.this.kms_key_id == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "A supplied BYO CMK must be used as the kms_key_id."
  }
}

run "provisioned_sets_shard_count" {
  command = plan

  variables {
    config = {
      name        = "test-events-prov"
      stream_mode = "PROVISIONED"
      shard_count = 2
    }
  }

  assert {
    condition     = aws_kinesis_stream.this.shard_count == 2
    error_message = "PROVISIONED streams must set the requested shard_count."
  }
}

run "unencrypted_requires_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "test-events-plain"
      allow_unencrypted = true
    }
  }

  assert {
    condition     = aws_kinesis_stream.this.encryption_type == "NONE"
    error_message = "Escape hatch must set encryption_type to NONE."
  }
}

# Negative case: stream_mode validation rejects an unknown mode.
run "invalid_stream_mode_is_rejected" {
  command = plan

  variables {
    config = {
      name        = "test-events-bad"
      stream_mode = "BURST"
    }
  }

  expect_failures = [
    var.config,
  ]
}
