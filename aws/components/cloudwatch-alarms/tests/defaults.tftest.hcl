# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids are unknown under the mock provider, so assertions target known and
# derived values (module counts, the enabled set size) plus plan success.

mock_provider "aws" {}

run "secure_defaults_full_baseline" {
  command = plan

  variables {
    config = {
      name_prefix               = "emag-prod"
      cloudtrail_log_group_name = "/aws/cloudtrail/emag-prod"
    }
  }

  # Full baseline = 15 security events => 15 filters + 15 alarms.
  assert {
    condition     = length(module.metric_filter) == 15
    error_message = "Default (no enabled_alarms) must provision the full 15-event baseline of metric filters."
  }

  assert {
    condition     = length(module.metric_alarm) == 15
    error_message = "Default (no enabled_alarms) must provision the full 15-event baseline of alarms."
  }

  # A dedicated SNS topic and CMK are created when neither is supplied.
  assert {
    condition     = length(module.topic) == 1
    error_message = "An SNS topic atom must be created when config.sns_topic_arn is null."
  }

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A KMS key atom must be created when neither sns_topic_arn nor kms_key_arn is supplied."
  }

  # Topic name and CMK alias are derived from name_prefix.
  assert {
    condition     = module.topic[0].manifest.name == "emag-prod-security-alarms"
    error_message = "Topic must be named <name_prefix>-security-alarms."
  }

  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/cloudwatch-alarms/emag-prod"
    error_message = "CMK alias must be derived as alias/cloudwatch-alarms/<name_prefix>."
  }

  # The unauthorized-api alarm is present in the full baseline and surfaced on the manifest.
  assert {
    condition     = contains(keys(output.manifest.alarm_arns), "unauthorized_api_calls")
    error_message = "manifest.alarm_arns must include the unauthorized_api_calls baseline alarm."
  }
}

run "subset_via_enabled_alarms" {
  command = plan

  variables {
    config = {
      name_prefix               = "emag-prod"
      cloudtrail_log_group_name = "/aws/cloudtrail/emag-prod"
      enabled_alarms = [
        "root_account_usage",
        "console_signin_without_mfa",
        "unauthorized_api_calls",
      ]
    }
  }

  assert {
    condition     = length(module.metric_filter) == 3
    error_message = "enabled_alarms subset must provision exactly the requested 3 filters."
  }

  assert {
    condition     = length(module.metric_alarm) == 3
    error_message = "enabled_alarms subset must provision exactly the requested 3 alarms."
  }
}

run "byo_topic_skips_topic_and_kms_creation" {
  command = plan

  variables {
    config = {
      name_prefix               = "emag-prod"
      cloudtrail_log_group_name = "/aws/cloudtrail/emag-prod"
      sns_topic_arn             = "arn:aws:sns:eu-central-1:111122223333:existing-alerts"
    }
  }

  assert {
    condition     = length(module.topic) == 0
    error_message = "No SNS topic atom must be created when config.sns_topic_arn is supplied."
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No KMS key atom must be created when a BYO topic is supplied."
  }

  assert {
    condition     = output.manifest.sns_topic_arn == "arn:aws:sns:eu-central-1:111122223333:existing-alerts"
    error_message = "manifest.sns_topic_arn must be the supplied BYO topic ARN."
  }

  # Filters/alarms are still provisioned for the full baseline against BYO topic.
  assert {
    condition     = length(module.metric_alarm) == 15
    error_message = "Full baseline alarms must still be created against a BYO topic."
  }
}

# --- Negative: an unknown alarm key in enabled_alarms -> validation failure. ---
run "unknown_alarm_key_is_rejected" {
  command = plan

  variables {
    config = {
      name_prefix               = "emag-prod"
      cloudtrail_log_group_name = "/aws/cloudtrail/emag-prod"
      enabled_alarms            = ["not_a_real_alarm"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
