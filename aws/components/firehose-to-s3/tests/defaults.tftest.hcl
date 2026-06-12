# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs are unknown, so we
# assert on known/derived values (counts, names, policy JSON, validation) and on
# plan success rather than on computed ARNs.

# Mock account/region/partition data sources with realistic values so the
# derived ARNs (bucket/log-group) the component builds pass the provider's ARN
# validation. Without this the mock provider invents non-ARN-shaped values.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
  mock_data "aws_region" {
    defaults = {
      name = "eu-central-1"
    }
  }
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name = "test-events"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # The four always-on atoms (bucket, log group, role, firehose) are each one instance.
  assert {
    condition     = length(module.delivery_bucket) == 1 && length(module.log_group) == 1 && length(module.firehose_role) == 1 && length(module.firehose) == 1
    error_message = "Delivery bucket, log group, role and firehose must each be composed exactly once."
  }

  # The bucket and log group names are derived from config.name (known at plan).
  assert {
    condition     = module.delivery_bucket.manifest.bucket == "test-events-firehose-delivery-111122223333"
    error_message = "Delivery bucket name must be derived from config.name and account id."
  }

  assert {
    condition     = module.log_group.manifest.name == "/aws/kinesisfirehose/test-events"
    error_message = "Error log group name must be derived from config.name."
  }

  # The created CMK alias is derived from config.name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/test-events/firehose-to-s3"
    error_message = "KMS alias must be derived from config.name."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name        = "test-events-byo"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key supplied -> no kms-key atom is created.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  # The component reports the BYO key as the effective encryption key.
  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "All atoms must be encrypted with the supplied BYO KMS key."
  }

  # manifest.kms_key_arn must echo the BYO key.
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "manifest.kms_key_arn must report the BYO key when one is supplied."
  }

  # With a known (BYO) KMS ARN the policy strings are fully resolvable at plan.
  # The firehose delivery role policy must grant S3 write, KMS use and CWL.
  assert {
    condition     = can(regex("s3:PutObject", local.firehose_inline_policy)) && can(regex("kms:GenerateDataKey", local.firehose_inline_policy)) && can(regex("logs:PutLogEvents", local.firehose_inline_policy))
    error_message = "Delivery role policy must allow s3:PutObject, kms:GenerateDataKey and logs:PutLogEvents."
  }

  # The KMS policy this component builds (used when it owns the CMK) must
  # authorise BOTH the firehose principal and the regional CloudWatch Logs one.
  assert {
    condition     = can(regex("firehose\\.amazonaws\\.com", local.kms_policy)) && can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant both firehose.amazonaws.com and the regional logs principal."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name        = "test-events-badarn"
      kms_key_arn = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
