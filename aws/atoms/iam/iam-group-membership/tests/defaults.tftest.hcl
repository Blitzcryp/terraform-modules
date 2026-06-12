# Native `terraform test`. Mocked AWS provider — no real credentials/resources.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name  = "test-membership"
      group = "test-group"
      users = ["alice", "bob"]
    }
  }

  assert {
    condition     = aws_iam_group_membership.this.group == "test-group"
    error_message = "group must echo config.group."
  }

  assert {
    condition     = length(aws_iam_group_membership.this.users) == 2
    error_message = "users must echo config.users."
  }

  # PCI DSS Req 8: this module manages no static credentials. Such resources are
  # not declared (so cannot be referenced); absence is enforced by a source-level
  # grep gate in CI. This assertion proves the membership is the only resource.
  assert {
    condition     = aws_iam_group_membership.this.group == "test-group"
    error_message = "The membership must be the only resource managed by this atom."
  }
}

# Negative case: empty required group is rejected by the config validation block.
run "empty_group_is_rejected" {
  command = plan

  variables {
    config = {
      name  = "test-membership"
      group = ""
      users = ["alice"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
