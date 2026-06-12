# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# Under mock_provider, computed values such as ARNs are unknown, so we assert on
# known/derived values (counts, names) and manifest nullness rather than ARNs.

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
    config = {
      name = "test-app"
    }
  }

  # No BYO key -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # Inspector enabled by default -> the enabler atom is created.
  assert {
    condition     = length(module.inspector) == 1
    error_message = "The inspector2-enabler atom must be created by default (enable_inspector=true)."
  }

  # Inspector is scoped to ECR scanning for this component.
  assert {
    condition     = module.inspector[0].manifest.resource_types == toset(["ECR"])
    error_message = "Inspector must be enabled for ECR scanning."
  }

  # Repository name passes through to the atom (known at plan time).
  assert {
    condition     = module.repository.manifest.name == "test-app"
    error_message = "Repository name must be passed through to the ecr-repository atom."
  }

  # Created CMK alias is derived from the repository name (known at plan time).
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/ecr/test-app"
    error_message = "KMS alias must be derived from the repository name."
  }

  # Manifest reports inspector enabled.
  assert {
    condition     = output.manifest.inspector_enabled == true
    error_message = "manifest.inspector_enabled must be true by default."
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

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The repository must be encrypted with the supplied BYO key."
  }
}

run "inspector_disabled_skips_enabler" {
  command = plan

  variables {
    config = {
      name             = "test-app-noinspector"
      enable_inspector = false
    }
  }

  assert {
    condition     = length(module.inspector) == 0
    error_message = "No inspector2-enabler atom must be created when enable_inspector=false."
  }

  assert {
    condition     = output.manifest.inspector_enabled == false
    error_message = "manifest.inspector_enabled must be false when disabled."
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
