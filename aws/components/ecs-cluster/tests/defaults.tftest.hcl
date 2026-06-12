# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under the mock, computed ARNs are unknown, so we assert
# on known/derived values (module instance counts, derived names, policy JSON,
# manifest nullness) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name = "test-app"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Log group name is derived from the cluster name (echoed by the atom, known
  # at plan time even under the mock provider).
  assert {
    condition     = module.log_group.manifest.name == "/ecs/test-app/exec"
    error_message = "Log group name must be derived from config.name."
  }

  # Cluster name is echoed (known at plan time).
  assert {
    condition     = module.ecs_cluster.manifest.name == "test-app"
    error_message = "Cluster name must equal config.name."
  }

  # The created CMK's alias is derived from name (known at plan time).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/ecs/test-app"
    error_message = "KMS alias must be derived from config.name."
  }

  # The KMS policy this component builds must authorise the regional CloudWatch
  # Logs service principal (apply-time correctness for CMK-encrypted log groups).
  assert {
    condition     = can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the CloudWatch Logs service principal use of the key."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name        = "test-app-byo"
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
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Log group + ECS Exec must be encrypted with the supplied BYO KMS key."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name        = "test-app-badarn"
      kms_key_arn = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
