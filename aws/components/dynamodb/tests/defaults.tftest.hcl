# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids are unknown under the mock provider, so assertions target known and
# derived values (module counts, derived names, the manifest) plus plan success.

mock_provider "aws" {}

run "secure_defaults_create_cmk_and_table" {
  command = plan

  variables {
    config = {
      name     = "orders"
      hash_key = "order_id"
      attributes = [
        { name = "order_id", type = "S" },
      ]
    }
  }

  # A dedicated CMK atom is created when no BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when config.kms_key_arn is null."
  }

  # CMK alias is derived from the table name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/dynamodb/orders"
    error_message = "KMS alias must be derived as alias/dynamodb/<name>."
  }

  # The table atom is created and its name is derived from config.
  assert {
    condition     = module.table.manifest.name == "orders"
    error_message = "The table atom must be created with the configured name."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      name        = "orders"
      hash_key    = "order_id"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
      attributes = [
        { name = "order_id", type = "S" },
      ]
    }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when config.kms_key_arn is supplied."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "manifest.kms_key_arn must be the supplied BYOK ARN."
  }
}

# --- Negative: invalid billing mode -> config validation fails. ---
run "invalid_billing_mode_is_rejected" {
  command = plan

  variables {
    config = {
      name         = "orders"
      hash_key     = "order_id"
      billing_mode = "ON_DEMAND"
      attributes = [
        { name = "order_id", type = "S" },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
