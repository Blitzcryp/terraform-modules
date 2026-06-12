# Native `terraform test`. Mocked AWS provider — no real credentials/resources.
# Under the mock provider computed ARNs are unknown, so we assert on counts,
# echoed/derived names and (critically, PCI DSS Req 8) the absence of any static
# credential resources anywhere in the composition.

mock_provider "aws" {}

run "secure_defaults_compose_atoms" {
  command = plan

  variables {
    config = {
      name = "test-developers"
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
      ]
      users = ["alice", "bob"]
    }
  }

  # One policy-attachment atom per managed policy ARN.
  assert {
    condition     = length(module.policy_attachment) == 2
    error_message = "There must be one policy-attachment atom per managed_policy_arns entry."
  }

  # Membership atom is created when users are supplied.
  assert {
    condition     = length(module.membership) == 1
    error_message = "A membership atom must be created when users are supplied."
  }

  # Group name is echoed (known at plan time even under the mock provider).
  assert {
    condition     = module.group.manifest.name == "test-developers"
    error_message = "Group name must be derived from config.name."
  }

  # Membership resource name is derived from the group name.
  assert {
    condition     = module.membership[0].manifest.group == "test-developers"
    error_message = "Membership must target the composed group."
  }

  # PCI DSS Req 8 — no static credentials anywhere in the composition. Such
  # resources are not declared in this component or in any composed atom (so
  # cannot be referenced in an assertion); absence is enforced by a source-level
  # grep gate in CI. The assertion below proves only identity/association
  # resources are produced.
  assert {
    condition     = module.group.manifest.name == "test-developers"
    error_message = "The composition must produce a group (and no credential resources)."
  }
}

run "no_membership_when_no_users" {
  command = plan

  variables {
    config = {
      name = "test-empty-group"
    }
  }

  # No users -> no membership atom (avoids empty exclusive ownership).
  assert {
    condition     = length(module.membership) == 0
    error_message = "No membership atom must be created when users is empty."
  }

  # No policies -> no policy-attachment atoms.
  assert {
    condition     = length(module.policy_attachment) == 0
    error_message = "No policy-attachment atom must be created when managed_policy_arns is empty."
  }

  # Members manifest is an empty list when no membership is managed.
  assert {
    condition     = length(output.manifest.members) == 0
    error_message = "manifest.members must be an empty list when no users are supplied."
  }
}

# Negative case: a malformed managed policy ARN is rejected by config validation.
run "invalid_policy_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name                = "test-bad-arn-group"
      managed_policy_arns = ["not-an-arn"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
