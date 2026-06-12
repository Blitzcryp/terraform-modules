# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# The child atom exposes only its `manifest` (not its config) and ARNs/ids are
# unknown under a mock provider — so assertions target known values: the child
# module instance count, the component's own manifest keys, and plan
# success/failure.

mock_provider "aws" {}

run "private_tier_baseline_plans" {
  command = plan

  variables {
    config = {
      name       = "private-tier"
      vpc_id     = "vpc-12345678"
      subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "-1"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
        },
        {
          rule_number = 110
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
          from_port   = 1024
          to_port     = 65535
        },
      ]
      egress_rules = [
        {
          rule_number = 100
          protocol    = "-1"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
        },
      ]
    }
  }

  # Exactly one network ACL atom is composed.
  assert {
    condition     = length(module.network_acl) == 1
    error_message = "The component must compose exactly one network-acl atom."
  }

  # The component manifest exposes the NACL id and arn keys (values are unknown
  # under the mock provider; the module-count assert proves composition).
  assert {
    condition     = can(output.manifest.network_acl_id) && can(output.manifest.network_acl_arn)
    error_message = "manifest must expose network_acl_id and network_acl_arn."
  }
}

run "no_rules_default_deny_plans" {
  command = plan

  variables {
    config = {
      name   = "locked-down"
      vpc_id = "vpc-12345678"
      # No rules — the tier denies everything (default-deny).
    }
  }

  assert {
    condition     = length(module.network_acl) == 1
    error_message = "A rule-less (default-deny) tier must still compose the atom and plan cleanly."
  }
}

# A public SSH ALLOW rule without the escape hatches must fail at plan time.
# The component validates this at its API boundary (var.config), mirroring the
# atom's lifecycle precondition.
run "public_ssh_allow_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name   = "bad-tier"
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "0.0.0.0/0"
          from_port   = 22
          to_port     = 22
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}

# A malformed rule (invalid rule_action) violates the atom's config validation,
# which surfaces on the child module's var.config.
run "invalid_rule_action_is_rejected" {
  command = plan

  variables {
    config = {
      name   = "bad-tier"
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "permit" # not allow/deny
          cidr_block  = "10.0.0.0/16"
          from_port   = 443
          to_port     = 443
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
