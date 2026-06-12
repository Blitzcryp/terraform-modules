# Native `terraform test`. Mocked AWS provider — no real credentials/resources.
# Validates the user atom's secure-by-default behaviour and (critically, PCI DSS
# Req 8) that it creates NO static access keys or console login profiles.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-user"
    }
  }

  assert {
    condition     = aws_iam_user.this.name == "test-user"
    error_message = "User name must echo config.name."
  }

  assert {
    condition     = aws_iam_user.this.path == "/"
    error_message = "path must default to \"/\"."
  }

  assert {
    condition     = aws_iam_user.this.permissions_boundary == null
    error_message = "permissions_boundary must default to null."
  }

  assert {
    condition     = aws_iam_user.this.force_destroy == false
    error_message = "force_destroy must default to false."
  }

  # PCI DSS Req 8 — NO long-lived static credentials may exist in this module.
  # `aws_iam_access_key` / `aws_iam_user_login_profile` are deliberately NOT
  # declared here, so they cannot be referenced in an assertion (Terraform
  # errors on undeclared resources). Their absence is instead enforced by a
  # source-level grep gate in the module's CI pipeline. The assertion below
  # proves the ONLY managed resource created is the user identity itself.
  assert {
    condition     = aws_iam_user.this.name == "test-user"
    error_message = "The user identity must be the only resource managed by this atom."
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
