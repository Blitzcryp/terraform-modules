# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name           = "test-recorder"
      s3_bucket_name = "test-config-bucket"
      iam_role_arn   = "arn:aws:iam::111122223333:role/test-config-role"
    }
  }

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].all_supported == true
    error_message = "Recorder must record all supported resource types by default (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].include_global_resource_types == true
    error_message = "Recorder must include global resource types by default."
  }

  assert {
    condition     = aws_config_configuration_recorder_status.this.is_enabled == true
    error_message = "The recorder must be started (is_enabled = true)."
  }

  # Recorder and delivery channel names are derived from config.name (known).
  assert {
    condition     = aws_config_delivery_channel.this.name == "test-recorder" && aws_config_configuration_recorder.this.name == "test-recorder"
    error_message = "Recorder and delivery channel names must be derived from config.name."
  }
}

# Negative case: an invalid IAM role ARN is rejected by the config validation.
run "invalid_role_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name           = "test-recorder"
      s3_bucket_name = "test-config-bucket"
      iam_role_arn   = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
