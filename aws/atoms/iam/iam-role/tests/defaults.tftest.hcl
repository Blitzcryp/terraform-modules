# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name               = "test-role"
      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    }
  }

  assert {
    condition     = aws_iam_role.this.max_session_duration == 3600
    error_message = "max_session_duration must default to 3600 (1h) (PCI DSS Req 8)."
  }

  assert {
    condition     = aws_iam_role.this.force_detach_policies == true
    error_message = "force_detach_policies must default to true."
  }

  assert {
    condition     = aws_iam_role.this.permissions_boundary == null
    error_message = "permissions_boundary must default to null."
  }
}

run "max_session_duration_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      assume_role_policy   = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
      max_session_duration = 60
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "admin_inline_policy_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name               = "test-admin-role"
      assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
      inline_policies = {
        full-admin = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
      }
      # allow_admin_policy intentionally left false
    }
  }

  expect_failures = [
    aws_iam_role.this,
  ]
}
