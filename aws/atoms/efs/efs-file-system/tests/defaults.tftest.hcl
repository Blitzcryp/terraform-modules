# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default behaviour. ARNs are
# unknown under the mock provider, so assertions target known/derived values.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-shared-fs"
    }
  }

  assert {
    condition     = aws_efs_file_system.this.encrypted == true
    error_message = "Encryption at rest must default to enabled (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_efs_file_system.this.creation_token == "test-shared-fs"
    error_message = "creation_token must be derived from config.name."
  }

  assert {
    condition     = aws_efs_file_system.this.performance_mode == "generalPurpose"
    error_message = "performance_mode must default to generalPurpose."
  }

  assert {
    condition     = aws_efs_file_system.this.throughput_mode == "bursting"
    error_message = "throughput_mode must default to bursting."
  }

  # TLS is enforced by default => the file-system policy is attached.
  assert {
    condition     = length(aws_efs_file_system_policy.this) == 1
    error_message = "A deny-non-TLS file-system policy must be attached by default (PCI DSS Req 4)."
  }

  # The default policy is exactly the deny-non-TLS statement.
  assert {
    condition     = length(local.policy_statements) == 1 && local.policy_statements[0].Sid == "DenyNonTLSAccess"
    error_message = "The default policy must contain the DenyNonTLSAccess statement."
  }

  assert {
    condition     = can(output.manifest.id) && can(output.manifest.arn) && can(output.manifest.dns_name)
    error_message = "manifest must expose id, arn and dns_name."
  }
}

run "tls_disabled_skips_policy" {
  command = plan

  variables {
    config = {
      name        = "test-no-tls"
      enforce_tls = false
    }
  }

  assert {
    condition     = length(aws_efs_file_system_policy.this) == 0
    error_message = "No file-system policy must be attached when enforce_tls=false and no extra statements are supplied."
  }
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name      = "test-unencrypted"
      encrypted = false
      # allow_unencrypted intentionally left at its false default
    }
  }

  expect_failures = [
    aws_efs_file_system.this,
  ]
}

run "provisioned_throughput_requires_value" {
  command = plan

  variables {
    config = {
      name            = "test-provisioned"
      throughput_mode = "provisioned"
      # provisioned_throughput_in_mibps intentionally omitted
    }
  }

  expect_failures = [
    var.config,
  ]
}
