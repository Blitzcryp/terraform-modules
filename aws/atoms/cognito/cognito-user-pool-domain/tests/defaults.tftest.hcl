# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the domain atom's behaviour.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      domain       = "test-auth-emag"
      user_pool_id = "eu-central-1_TESTPOOL0"
    }
  }

  assert {
    condition     = aws_cognito_user_pool_domain.this.domain == "test-auth-emag"
    error_message = "Domain must be passed through to the resource."
  }

  assert {
    condition     = aws_cognito_user_pool_domain.this.user_pool_id == "eu-central-1_TESTPOOL0"
    error_message = "user_pool_id must be passed through to the resource."
  }

  assert {
    condition     = aws_cognito_user_pool_domain.this.certificate_arn == null
    error_message = "certificate_arn must default to null (Cognito-prefix domain)."
  }
}

run "empty_domain_is_rejected" {
  command = plan

  variables {
    config = {
      domain       = ""
      user_pool_id = "eu-central-1_TESTPOOL0"
    }
  }

  expect_failures = [
    var.config,
  ]
}
