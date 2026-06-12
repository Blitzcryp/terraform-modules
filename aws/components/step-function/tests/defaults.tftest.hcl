# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under the mock, computed ARNs/IDs are unknown, so we
# assert on known/derived values (module instance counts, derived log group
# name, manifest nullness, inline policy wiring) and on plan success rather than
# on computed ARNs.

mock_provider "aws" {}

variables {
  definition = "{\"Comment\":\"test\",\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Pass\",\"End\":true}}}"
  base = {
    name       = "test-workflow"
    definition = "{\"Comment\":\"test\",\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Pass\",\"End\":true}}}"
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = var.base
  }

  # No BYO key -> the component creates a CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A CMK must be created when no BYO key is supplied."
  }

  # Log group name follows the vended-logs convention.
  assert {
    condition     = module.log_group.manifest.name == "/aws/vendedlogs/states/test-workflow"
    error_message = "Log group name must be /aws/vendedlogs/states/<name>."
  }

  # State machine name echoed through.
  assert {
    condition     = module.state_machine.manifest.name == "test-workflow"
    error_message = "State machine name must equal config.name."
  }

  # Logging level ALL is the secure default fed into the state machine atom.
  assert {
    condition     = var.config.log_level == "ALL"
    error_message = "Logging level must default to ALL (PCI DSS Req 10)."
  }

  # Execution data must not be logged by default (may carry CHD).
  assert {
    condition     = var.config.include_execution_data == false
    error_message = "include_execution_data must default to false (PCI DSS Req 3)."
  }

  # Without additional_policy_json, only the observability policy is attached.
  assert {
    condition     = !contains(keys(local.inline_policies), "workflow")
    error_message = "No workflow policy must be attached when additional_policy_json is unset."
  }

  assert {
    condition     = contains(keys(local.inline_policies), "observability")
    error_message = "The observability inline policy (logs + X-Ray) must always be attached."
  }
}

run "additional_policy_attaches_workflow_inline_policy" {
  command = plan

  variables {
    config = merge(var.base, {
      additional_policy_json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"*\"}]}"
    })
  }

  assert {
    condition     = contains(keys(local.inline_policies), "workflow")
    error_message = "A workflow inline policy must be attached when additional_policy_json is set."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = merge(var.base, {
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    })
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No CMK must be created when a BYO key is supplied."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Manifest kms_key_arn must be the BYO key."
  }
}

# Negative case (validation): an invalid type is rejected.
run "invalid_type_is_rejected" {
  command = plan

  variables {
    config = merge(var.base, {
      type = "TURBO"
    })
  }

  expect_failures = [
    var.config,
  ]
}
