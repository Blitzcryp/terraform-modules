# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour. ARNs
# are unknown under the mock provider, so assertions target known/derived values
# plus overall plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name     = "orders"
      hash_key = "order_id"
      attributes = [
        { name = "order_id", type = "S" },
      ]
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  # CMK SSE block is present with the supplied key.
  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].enabled == true
    error_message = "Server-side encryption must be enabled with a CMK by default (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_dynamodb_table.this.server_side_encryption[0].kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "SSE must use the supplied customer-managed KMS key."
  }

  # Point-in-time recovery on by default.
  assert {
    condition     = aws_dynamodb_table.this.point_in_time_recovery[0].enabled == true
    error_message = "Point-in-time recovery must default to enabled."
  }

  # Deletion protection on by default.
  assert {
    condition     = aws_dynamodb_table.this.deletion_protection_enabled == true
    error_message = "Deletion protection must default to enabled."
  }

  # PAY_PER_REQUEST is the default billing mode.
  assert {
    condition     = aws_dynamodb_table.this.billing_mode == "PAY_PER_REQUEST"
    error_message = "Billing mode must default to PAY_PER_REQUEST."
  }
}

run "aws_owned_key_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name     = "orders"
      hash_key = "order_id"
      attributes = [
        { name = "order_id", type = "S" },
      ]
      allow_aws_owned_key = true
    }
  }

  # No SSE block when using the AWS-owned key.
  assert {
    condition     = length(aws_dynamodb_table.this.server_side_encryption) == 0
    error_message = "No customer SSE block must be present when using the AWS-owned key."
  }
}

# --- Negative: no CMK and no escape hatch -> precondition fails (PCI Req 3). ---
run "no_cmk_without_escape_hatch_is_blocked" {
  command = plan

  variables {
    config = {
      name     = "orders"
      hash_key = "order_id"
      attributes = [
        { name = "order_id", type = "S" },
      ]
      # kms_key_arn null and allow_aws_owned_key left at its false default
    }
  }

  expect_failures = [
    aws_dynamodb_table.this,
  ]
}

# --- Negative: PITR off without escape hatch -> precondition fails. ---
run "no_pitr_without_escape_hatch_is_blocked" {
  command = plan

  variables {
    config = {
      name     = "orders"
      hash_key = "order_id"
      attributes = [
        { name = "order_id", type = "S" },
      ]
      kms_key_arn                   = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      enable_point_in_time_recovery = false
      # allow_no_pitr left at its false default
    }
  }

  expect_failures = [
    aws_dynamodb_table.this,
  ]
}

# --- Negative: PROVISIONED without capacities -> config validation fails. ---
run "provisioned_without_capacity_is_rejected" {
  command = plan

  variables {
    config = {
      name         = "orders"
      hash_key     = "order_id"
      billing_mode = "PROVISIONED"
      attributes = [
        { name = "order_id", type = "S" },
      ]
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    }
  }

  expect_failures = [
    var.config,
  ]
}
