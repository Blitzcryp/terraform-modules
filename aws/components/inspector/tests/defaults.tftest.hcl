# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# Under mock_provider, computed values such as ARNs are unknown, so we assert on
# known/derived values (counts, names, policy JSON) and manifest nullness.

# A 12-digit account id so the inspector2-enabler atom's account_ids default
# (current account) passes the AWS provider's account-id validation under mock.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {}
  }

  # Inspector enrolment is always created.
  assert {
    condition     = module.inspector.manifest.resource_types == toset(["ECR", "EC2", "LAMBDA"])
    error_message = "Inspector must default to scanning ECR, EC2 and LAMBDA."
  }

  # No BYO key -> the component owns the CMK for the topic.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Notification topic created by default.
  assert {
    condition     = length(module.notification_topic) == 1
    error_message = "The findings-notification SNS topic must be created by default."
  }

  # The CMK policy must authorise the EventBridge service principal (the future
  # EventBridge rule needs to use the key when publishing findings).
  assert {
    condition     = can(regex("events\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the EventBridge service principal use of the key."
  }

  # Created CMK alias is known at plan time.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/inspector/findings"
    error_message = "KMS alias must be 'alias/inspector/findings'."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The SNS topic must be encrypted with the supplied BYO key."
  }
}

run "no_topic_when_disabled" {
  command = plan

  variables {
    config = {
      create_notification_topic = false
    }
  }

  assert {
    condition     = length(module.notification_topic) == 0
    error_message = "No SNS topic must be created when create_notification_topic=false."
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No CMK must be created when there is no topic to encrypt."
  }

  assert {
    condition     = output.manifest.notification_topic_arn == null && output.manifest.kms_key_arn == null
    error_message = "notification_topic_arn and kms_key_arn must be null when no topic is created."
  }
}

# Negative case: an invalid resource type is rejected by config validation.
run "invalid_resource_type_is_rejected" {
  command = plan

  variables {
    config = {
      resource_types = ["NOT_A_TYPE"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
