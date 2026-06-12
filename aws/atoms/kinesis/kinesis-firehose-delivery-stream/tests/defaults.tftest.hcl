# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name        = "test-delivery"
      bucket_arn  = "arn:aws:s3:::test-firehose-delivery"
      role_arn    = "arn:aws:iam::111122223333:role/test-firehose-role"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.destination == "extended_s3"
    error_message = "Destination must be extended_s3."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].enabled == true
    error_message = "Server-side encryption must be enabled by default (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].key_type == "CUSTOMER_MANAGED_CMK"
    error_message = "SSE must use a CUSTOMER_MANAGED_CMK by default."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "SSE must use the supplied CMK ARN."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.extended_s3_configuration[0].kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "S3 delivery must be encrypted with the supplied CMK (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.extended_s3_configuration[0].buffering_size == 5
    error_message = "Buffering size must default to 5 MB."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.extended_s3_configuration[0].buffering_interval == 300
    error_message = "Buffering interval must default to 300 seconds."
  }
}

run "cloudwatch_logging_enabled_when_group_set" {
  command = plan

  variables {
    config = {
      name                      = "test-delivery-logs"
      bucket_arn                = "arn:aws:s3:::test-firehose-delivery"
      role_arn                  = "arn:aws:iam::111122223333:role/test-firehose-role"
      kms_key_arn               = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      cloudwatch_log_group_name = "/aws/kinesisfirehose/test-delivery-logs"
    }
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.extended_s3_configuration[0].cloudwatch_logging_options[0].enabled == true
    error_message = "CloudWatch logging must be enabled when a log group is supplied (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.extended_s3_configuration[0].cloudwatch_logging_options[0].log_group_name == "/aws/kinesisfirehose/test-delivery-logs"
    error_message = "CloudWatch log group name must be passed through."
  }
}

run "unencrypted_requires_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "test-delivery-plain"
      bucket_arn        = "arn:aws:s3:::test-firehose-delivery"
      role_arn          = "arn:aws:iam::111122223333:role/test-firehose-role"
      allow_unencrypted = true
    }
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].enabled == false
    error_message = "Escape hatch must disable server-side encryption."
  }

  assert {
    condition     = aws_kinesis_firehose_delivery_stream.this.server_side_encryption[0].key_type == "AWS_OWNED_CMK"
    error_message = "With SSE disabled, key_type must fall back to AWS_OWNED_CMK."
  }
}

# Negative case: SSE without a CMK and without the escape hatch is rejected.
run "encryption_without_key_is_rejected" {
  command = plan

  variables {
    config = {
      name       = "test-delivery-bad"
      bucket_arn = "arn:aws:s3:::test-firehose-delivery"
      role_arn   = "arn:aws:iam::111122223333:role/test-firehose-role"
    }
  }

  expect_failures = [
    var.config,
  ]
}
