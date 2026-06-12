# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs are unknown, so we
# assert on known/derived values (counts, names, policy JSON, validation) and on
# plan success rather than on computed ARNs.

# Mock the account/region/partition data sources with realistic values so the
# derived ARNs (trail/bucket/log-group) the component builds pass the provider's
# ARN validation. Without this the mock provider invents non-ARN-shaped values.
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
      name = "test-audit"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # The four always-on atoms (bucket, log group, role, trail) are each one instance.
  assert {
    condition     = length(module.log_bucket) == 1 && length(module.log_group) == 1 && length(module.cloudwatch_role) == 1 && length(module.trail) == 1
    error_message = "Log bucket, log group, delivery role and trail must each be composed exactly once."
  }

  # The trail name and log group name are derived from config.name (known at plan).
  assert {
    condition     = module.log_group.manifest.name == "/aws/cloudtrail/test-audit"
    error_message = "Log group name must be derived from config.name."
  }

  # The created CMK alias is derived from config.name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/test-audit/cloudtrail"
    error_message = "KMS alias must be derived from config.name."
  }

  # The KMS policy this component builds must authorise BOTH the CloudTrail
  # service principal and the regional CloudWatch Logs service principal
  # (apply-time correctness for log delivery + CMK-encrypted log groups).
  assert {
    condition     = can(regex("cloudtrail\\.amazonaws\\.com", local.kms_policy)) && can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant both cloudtrail.amazonaws.com and the regional logs principal."
  }

  # The CloudTrail KMS grant must include GenerateDataKey* and Decrypt.
  assert {
    condition     = can(regex("kms:GenerateDataKey\\*", local.kms_policy)) && can(regex("kms:Decrypt", local.kms_policy))
    error_message = "KMS policy must grant CloudTrail GenerateDataKey* and Decrypt."
  }

  # The S3 bucket policy injected into the s3-bucket atom must contain both the
  # AclCheck and Write statements, scoped to the trail's SourceArn.
  assert {
    condition     = length(local.bucket_policy_statements) == 2 && local.bucket_policy_statements[0].Sid == "AWSCloudTrailAclCheck" && local.bucket_policy_statements[1].Sid == "AWSCloudTrailWrite"
    error_message = "Bucket policy must inject AWSCloudTrailAclCheck (GetBucketAcl) and AWSCloudTrailWrite (PutObject)."
  }

  # The CloudTrail->CWL delivery policy must allow CreateLogStream + PutLogEvents.
  assert {
    condition     = can(regex("logs:CreateLogStream", local.cloudtrail_inline_policy)) && can(regex("logs:PutLogEvents", local.cloudtrail_inline_policy))
    error_message = "Delivery role inline policy must allow CreateLogStream and PutLogEvents."
  }

  # The trail must receive the log-stream-scoped CWL group ARN (ending with :*).
  assert {
    condition     = can(regex(":\\*$", local.cloud_watch_logs_group_arn_for_trail))
    error_message = "CloudTrail cloud_watch_logs_group_arn must be the log-stream-scoped form ending in :*."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name        = "test-audit-byo"
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
    error_message = "Trail and log group must be encrypted with the supplied BYO KMS key."
  }

  # manifest.kms_key_arn must echo the BYO key.
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "manifest.kms_key_arn must report the BYO key when one is supplied."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name        = "test-audit-badarn"
      kms_key_arn = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
