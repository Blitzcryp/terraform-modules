# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids/urls are unknown under the mock provider, so assertions target known
# and derived values (module counts, derived names/aliases, manifest nullness)
# plus overall plan success.

mock_provider "aws" {}

run "secure_defaults_compose_encrypted_queue_with_dlq" {
  command = plan

  variables {
    config = {
      name = "emag-test-jobs"
    }
  }

  # A dedicated KMS key atom is created when no BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when config.kms_key_arn is null."
  }

  # KMS alias is derived from the queue name (sqs/<name>).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/sqs/emag-test-jobs"
    error_message = "KMS alias must be derived as alias/sqs/<name>."
  }

  # The queue atom is planned with the requested name.
  assert {
    condition     = module.queue.manifest.name == "emag-test-jobs"
    error_message = "Queue atom must be planned with the requested name."
  }

  # Manifest surfaces the queue name.
  assert {
    condition     = output.manifest.queue_name == "emag-test-jobs"
    error_message = "manifest.queue_name must echo the configured name."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      name        = "emag-test-jobs"
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

run "dlq_disabled_creates_no_dlq_and_nulls_manifest" {
  command = plan

  variables {
    config = {
      name       = "emag-test-jobs"
      enable_dlq = false
    }
  }

  # manifest.dlq_arn must be null when no DLQ exists.
  assert {
    condition     = output.manifest.dlq_arn == null
    error_message = "manifest.dlq_arn must be null when the DLQ is disabled."
  }
}

# --- Negative case: FIFO queue name without the required '.fifo' suffix. ---
run "fifo_name_without_suffix_is_rejected" {
  command = plan

  variables {
    config = {
      name       = "emag-test-jobs"
      fifo_queue = true
    }
  }

  expect_failures = [
    var.config,
  ]
}
