# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids are unknown under the mock provider, so assertions target known and
# derived values (module counts, derived names, the component manifest) plus
# overall plan success. Atom inputs are not readable, so we assert on the atoms'
# `manifest` outputs (which echo known inputs like bucket names) and on the
# component's own output manifest.

mock_provider "aws" {}

run "secure_defaults_compose_locked_down_bucket" {
  command = plan

  variables {
    config = {
      bucket = "emag-test-pci-bucket"
    }
  }

  # A dedicated KMS key atom is created when no BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when config.kms_key_arn is null."
  }

  # KMS alias is derived from the bucket name (s3/<bucket>).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/s3/emag-test-pci-bucket"
    error_message = "KMS alias must be derived as alias/s3/<bucket>."
  }

  # The main bucket atom is planned with the requested bucket name.
  assert {
    condition     = module.bucket.manifest.bucket == "emag-test-pci-bucket"
    error_message = "Main bucket atom must be planned with the requested bucket name."
  }

  # Access logging on by default: a companion log bucket is created.
  assert {
    condition     = length(module.log_bucket) == 1
    error_message = "A companion log bucket must be created when access logging is on and no external bucket is supplied."
  }

  # Companion log bucket name is derived from the main bucket name.
  assert {
    condition     = module.log_bucket[0].manifest.bucket == "emag-test-pci-bucket-logs"
    error_message = "Companion log bucket must be named <bucket>-logs."
  }

  # The component manifest exposes the companion log bucket name.
  assert {
    condition     = output.manifest.log_bucket_name == "emag-test-pci-bucket-logs"
    error_message = "manifest.log_bucket_name must be the companion log bucket name."
  }

  # The main bucket name is surfaced on the manifest.
  assert {
    condition     = output.manifest.bucket_name == "emag-test-pci-bucket"
    error_message = "manifest.bucket_name must echo the configured bucket."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      bucket      = "emag-test-pci-bucket"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # No KMS atom created when a BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when config.kms_key_arn is supplied."
  }

  # The supplied ARN flows through to the manifest; kms_key_id is null (BYOK).
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "manifest.kms_key_arn must be the supplied BYOK ARN."
  }

  assert {
    condition     = output.manifest.kms_key_id == null
    error_message = "manifest.kms_key_id must be null when the key is BYOK."
  }
}

run "external_log_bucket_skips_companion" {
  command = plan

  variables {
    config = {
      bucket            = "emag-test-pci-bucket"
      access_log_bucket = "central-access-logs"
    }
  }

  # No companion log bucket created when an external one is supplied.
  assert {
    condition     = length(module.log_bucket) == 0
    error_message = "No companion log bucket must be created when an external access_log_bucket is supplied."
  }

  # manifest.log_bucket_name is null when an external bucket is used.
  assert {
    condition     = output.manifest.log_bucket_name == null
    error_message = "manifest.log_bucket_name must be null when an external log bucket is supplied."
  }
}

run "logging_disabled_skips_companion" {
  command = plan

  variables {
    config = {
      bucket                = "emag-test-pci-bucket"
      enable_access_logging = false
    }
  }

  assert {
    condition     = length(module.log_bucket) == 0
    error_message = "No companion log bucket must be created when access logging is disabled."
  }

  assert {
    condition     = output.manifest.log_bucket_name == null
    error_message = "manifest.log_bucket_name must be null when access logging is disabled."
  }
}

# --- Negative case: invalid bucket name is rejected by config validation. ---
run "invalid_bucket_name_is_rejected" {
  command = plan

  variables {
    config = {
      bucket = "Invalid_Bucket_NAME"
    }
  }

  expect_failures = [
    var.config,
  ]
}
