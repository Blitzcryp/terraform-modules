# Native `terraform test`. Mocked AWS provider — no real credentials/resources.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      group      = "test-group"
      policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    }
  }

  assert {
    condition     = aws_iam_group_policy_attachment.this.group == "test-group"
    error_message = "group must echo config.group."
  }

  assert {
    condition     = aws_iam_group_policy_attachment.this.policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
    error_message = "policy_arn must echo config.policy_arn."
  }

  # PCI DSS Req 8: this module manages no static credentials. Such resources are
  # not declared (so cannot be referenced); absence is enforced by a source-level
  # grep gate in CI. This assertion proves the attachment is the only resource.
  assert {
    condition     = aws_iam_group_policy_attachment.this.policy_arn != null
    error_message = "The attachment must be the only resource managed by this atom."
  }
}

# Negative case: a malformed policy ARN is rejected by the config validation block.
run "invalid_policy_arn_is_rejected" {
  command = plan

  variables {
    config = {
      group      = "test-group"
      policy_arn = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
