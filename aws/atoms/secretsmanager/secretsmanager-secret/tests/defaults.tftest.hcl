# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour. ARNs
# and ids are unknown under the mock provider, so assertions target known and
# derived values (resource counts, echoed config, the manifest) plus plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name        = "example/app/db-password"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # CMK encryption is wired through to the resource (PCI DSS Req 3).
  assert {
    condition     = aws_secretsmanager_secret.this.kms_key_id == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "Secret must be encrypted with the supplied CMK ARN."
  }

  # Recovery window defaults to 30 days.
  assert {
    condition     = aws_secretsmanager_secret.this.recovery_window_in_days == 30
    error_message = "recovery_window_in_days must default to 30."
  }

  # No rotation schedule unless a lambda is supplied.
  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 0
    error_message = "No rotation resource must be created without a rotation_lambda_arn."
  }

  # No resource policy unless one is supplied.
  assert {
    condition     = length(aws_secretsmanager_secret_policy.this) == 0
    error_message = "No secret policy must be created without config.policy."
  }

  # The manifest echoes the known secret name.
  assert {
    condition     = output.manifest.secret_name == "example/app/db-password"
    error_message = "manifest.secret_name must echo the configured name."
  }
}

run "rotation_enabled_when_lambda_supplied" {
  command = plan

  variables {
    config = {
      name                = "example/app/db-password"
      kms_key_arn         = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      rotation_lambda_arn = "arn:aws:lambda:eu-central-1:111122223333:function:rotate-db"
      rotation_days       = 14
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 1
    error_message = "A rotation resource must be created when a rotation_lambda_arn is supplied."
  }

  assert {
    condition     = aws_secretsmanager_secret_rotation.this[0].rotation_rules[0].automatically_after_days == 14
    error_message = "rotation_rules.automatically_after_days must reflect config.rotation_days."
  }
}

# --- Negative case: AWS-managed key (kms_key_arn=null) without the escape hatch
# is blocked by the lifecycle precondition. ---
run "aws_managed_key_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name = "example/app/db-password"
      # kms_key_arn intentionally omitted; allow_aws_managed_key left at false.
    }
  }

  expect_failures = [
    aws_secretsmanager_secret.this,
  ]
}

# --- Negative case: immediate deletion (recovery_window_in_days=0) without the
# escape hatch is blocked by the lifecycle precondition. ---
run "immediate_deletion_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name                    = "example/app/db-password"
      kms_key_arn             = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      recovery_window_in_days = 0
      # allow_immediate_deletion left at false.
    }
  }

  expect_failures = [
    aws_secretsmanager_secret.this,
  ]
}

# --- Negative case: recovery window out of range is rejected by config validation. ---
run "recovery_window_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      name                    = "example/app/db-password"
      kms_key_arn             = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      recovery_window_in_days = 3
    }
  }

  expect_failures = [
    var.config,
  ]
}
