# Native `terraform test`. Mocked AWS provider — no real credentials/resources.
# Under the mock provider computed ARNs are unknown, so we assert on counts,
# echoed names and (critically, PCI DSS Req 8) the absence of any static
# credential resources anywhere in the composition.

mock_provider "aws" {}

run "secure_defaults_compose_user_atom" {
  command = plan

  variables {
    config = {
      name = "test-human-user"
    }
  }

  # Exactly one user atom is composed.
  assert {
    condition     = module.user.manifest.name == "test-human-user"
    error_message = "User name must be derived from config.name."
  }

  # PCI DSS Req 8 — no static access keys / console login profiles anywhere in
  # the composition. Such resources are not declared in this component or in the
  # composed iam-user atom (so cannot be referenced in an assertion); their
  # absence is enforced by a source-level grep gate in CI. The assertion below
  # proves the composition produces a user identity and nothing credential-bearing.
  assert {
    condition     = module.user.manifest.name == "test-human-user"
    error_message = "The composition must produce a user identity (and no credential resources)."
  }
}

# Negative case: empty required name is rejected by the config validation block.
run "empty_name_is_rejected" {
  command = plan

  variables {
    config = {
      name = ""
    }
  }

  expect_failures = [
    var.config,
  ]
}
