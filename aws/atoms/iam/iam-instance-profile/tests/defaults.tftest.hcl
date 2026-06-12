# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed. NOTE: under mock_provider the ARN/unique_id are
# unknown, so we assert on known/derived values and on plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-instance-profile"
      role = "test-ec2-app-role"
    }
  }

  assert {
    condition     = aws_iam_instance_profile.this.path == "/"
    error_message = "path must default to \"/\"."
  }

  assert {
    condition     = aws_iam_instance_profile.this.role == "test-ec2-app-role"
    error_message = "role must echo the configured role name."
  }

  assert {
    condition     = aws_iam_instance_profile.this.name == "test-instance-profile"
    error_message = "name must echo the configured value."
  }
}

run "empty_role_is_rejected" {
  command = plan

  variables {
    config = {
      name = "test-instance-profile"
      role = ""
    }
  }

  expect_failures = [
    var.config,
  ]
}
