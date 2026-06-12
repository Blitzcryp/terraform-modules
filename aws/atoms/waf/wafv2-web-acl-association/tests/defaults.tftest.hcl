# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. The association id is computed under the mock provider,
# so we assert on known/derived inputs and on plan success + negative validation.

mock_provider "aws" {}

run "binds_acl_to_resource" {
  command = plan

  variables {
    config = {
      web_acl_arn  = "arn:aws:wafv2:eu-central-1:111122223333:regional/webacl/example/abcd1234-ab12-cd34-ef56-abcdef123456"
      resource_arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/example-alb/0123456789abcdef"
    }
  }

  assert {
    condition     = aws_wafv2_web_acl_association.this.web_acl_arn == "arn:aws:wafv2:eu-central-1:111122223333:regional/webacl/example/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The association must reference the supplied Web ACL ARN."
  }

  assert {
    condition     = aws_wafv2_web_acl_association.this.resource_arn == "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/example-alb/0123456789abcdef"
    error_message = "The association must reference the supplied resource ARN."
  }
}

# Negative case: a non-WAFv2 web_acl_arn is rejected by the config validation block.
run "invalid_web_acl_arn_is_rejected" {
  command = plan

  variables {
    config = {
      web_acl_arn  = "not-an-arn"
      resource_arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/example-alb/0123456789abcdef"
    }
  }

  expect_failures = [
    var.config,
  ]
}
