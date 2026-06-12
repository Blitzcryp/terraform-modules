# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider, computed values such as the policy ARN are unknown,
# so we assert on known/derived values and on plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name   = "test-policy"
      policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"ssm:GetParameter\",\"Resource\":\"arn:aws:ssm:eu-central-1:123456789012:parameter/app/*\"}]}"
    }
  }

  assert {
    condition     = aws_iam_policy.this.path == "/"
    error_message = "path must default to \"/\"."
  }

  assert {
    condition     = aws_iam_policy.this.name == "test-policy"
    error_message = "name must echo the configured value."
  }

  assert {
    condition     = local.grants_admin == false
    error_message = "A scoped policy must not be detected as admin."
  }
}

run "invalid_policy_json_is_rejected" {
  command = plan

  variables {
    config = {
      name   = "test-bad-json"
      policy = "not-valid-json"
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "admin_policy_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name   = "test-admin-policy"
      policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
      # allow_admin_policy intentionally left false
    }
  }

  expect_failures = [
    aws_iam_policy.this,
  ]
}

run "admin_policy_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name               = "test-admin-policy-ok"
      policy             = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
      allow_admin_policy = true
    }
  }

  assert {
    condition     = local.grants_admin == true
    error_message = "Admin policy must be detected as admin."
  }
}
