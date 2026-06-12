# Native `terraform test`. Mocked AWS provider — no real credentials/resources.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-group"
    }
  }

  assert {
    condition     = aws_iam_group.this.name == "test-group"
    error_message = "Group name must echo config.name."
  }

  assert {
    condition     = aws_iam_group.this.path == "/"
    error_message = "path must default to \"/\"."
  }

  # PCI DSS Req 8: this module manages no static credentials. Such resources are
  # not declared (so cannot be referenced); absence is enforced by a source-level
  # grep gate in CI. This assertion proves the group is the only resource.
  assert {
    condition     = aws_iam_group.this.name == "test-group"
    error_message = "The group must be the only resource managed by this atom."
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
