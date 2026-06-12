# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# ARNs/ids are unknown under the mock provider, so assertions target known and
# derived values (module counts, derived names/aliases/patterns) plus plan success.

mock_provider "aws" {}

run "secure_defaults_compose_full_pipeline" {
  command = plan

  variables {
    config = {
      name = "emag-security"
    }
  }

  # A dedicated KMS key atom is created when no BYOK ARN is supplied.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when config.kms_key_arn is null."
  }

  # KMS alias is derived from the base name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/findings-notification/emag-security"
    error_message = "KMS alias must be derived as alias/findings-notification/<name>."
  }

  # Topic name is derived as <name>-findings.
  assert {
    condition     = module.topic.manifest.name == "emag-security-findings"
    error_message = "Topic atom must be planned with the derived name <name>-findings."
  }

  # Rule name is derived as <name>-findings.
  assert {
    condition     = module.rule.manifest.name == "emag-security-findings"
    error_message = "Rule atom must be planned with the derived name <name>-findings."
  }

  # The target is wired to the same rule the component created (rule->topic).
  assert {
    condition     = module.target.manifest.rule == module.rule.manifest.name
    error_message = "Target must attach to the rule created by this component."
  }

  # Target id is derived from the base name and surfaced on the manifest.
  assert {
    condition     = module.target.manifest.target_id == "emag-security-sns"
    error_message = "Target id must be derived as <name>-sns."
  }
}

run "single_source_plan_succeeds" {
  command = plan

  variables {
    config = {
      name   = "emag-gd"
      source = "guardduty"
    }
  }

  # A single source still produces a full pipeline: rule + topic + target.
  assert {
    condition     = module.rule.manifest.name == "emag-gd-findings"
    error_message = "Rule must be created with the derived name for a single source."
  }

  assert {
    condition     = module.target.manifest.target_id == "emag-gd-sns"
    error_message = "Target id must be derived for a single source."
  }
}

run "byok_skips_kms_atom_and_uses_supplied_arn" {
  command = plan

  variables {
    config = {
      name        = "emag-security"
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"
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

run "additional_event_pattern_overrides_derived" {
  command = plan

  variables {
    config = {
      name                     = "emag-custom"
      additional_event_pattern = "{\"source\":[\"aws.securityhub\"]}"
    }
  }

  # A custom override still produces a valid plan with the rule/target wired.
  assert {
    condition     = module.target.manifest.rule == module.rule.manifest.name
    error_message = "Override pattern must still produce a wired rule->target pipeline."
  }
}

# --- Negative: an invalid source -> validation failure. ---
run "invalid_source_is_rejected" {
  command = plan

  variables {
    config = {
      name   = "emag-bad"
      source = "macie"
    }
  }

  expect_failures = [
    var.config,
  ]
}
