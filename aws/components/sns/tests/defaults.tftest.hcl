# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids are unknown under the mock provider, so assertions target known and
# derived values (module counts, derived names/aliases, manifest nullness) plus
# overall plan success.

mock_provider "aws" {}

run "secure_defaults_compose_encrypted_topic" {
  command = plan

  variables {
    config = {
      name = "emag-test-events"
    }
  }

  # A dedicated KMS key atom is created when no BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when config.kms_key_arn is null."
  }

  # KMS alias is derived from the topic name (sns/<name>).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/sns/emag-test-events"
    error_message = "KMS alias must be derived as alias/sns/<name>."
  }

  # The topic atom is planned with the requested name.
  assert {
    condition     = module.topic.manifest.name == "emag-test-events"
    error_message = "Topic atom must be planned with the requested name."
  }

  # No subscriptions requested by default.
  assert {
    condition     = length(module.subscription) == 0
    error_message = "No subscription atoms must be created when none are requested."
  }

  # Manifest surfaces the topic name and an empty subscription list.
  assert {
    condition     = output.manifest.topic_name == "emag-test-events"
    error_message = "manifest.topic_name must echo the configured name."
  }

  assert {
    condition     = length(output.manifest.subscription_arns) == 0
    error_message = "manifest.subscription_arns must be empty when no subscriptions are requested."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      name        = "emag-test-events"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # No KMS atom created when a BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when config.kms_key_arn is supplied."
  }

  # The supplied ARN flows through to the manifest.
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "manifest.kms_key_arn must be the supplied BYOK ARN."
  }
}

run "subscriptions_create_one_atom_each" {
  command = plan

  variables {
    config = {
      name = "emag-test-events"
      subscriptions = [
        { protocol = "sqs", endpoint = "arn:aws:sqs:eu-central-1:111122223333:q1" },
        { protocol = "sqs", endpoint = "arn:aws:sqs:eu-central-1:111122223333:q2" },
      ]
    }
  }

  assert {
    condition     = length(module.subscription) == 2
    error_message = "One subscription atom must be created per subscriptions entry."
  }
}

# --- Negative case: FIFO topic name without the required '.fifo' suffix. ---
run "fifo_name_without_suffix_is_rejected" {
  command = plan

  variables {
    config = {
      name       = "emag-test-events"
      fifo_topic = true
    }
  }

  expect_failures = [
    var.config,
  ]
}
