# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name            = "test-alb"
      subnets         = ["subnet-aaaa", "subnet-bbbb"]
      security_groups = ["sg-aaaa"]
    }
  }

  assert {
    condition     = aws_lb.this.internal == true
    error_message = "ALB must default to internal (not internet-facing) (PCI DSS Req 1)."
  }

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields == true
    error_message = "ALB must drop invalid header fields by default (PCI DSS Req 4)."
  }

  assert {
    condition     = aws_lb.this.enable_deletion_protection == true
    error_message = "ALB must enable deletion protection by default."
  }

  assert {
    condition     = aws_lb.this.desync_mitigation_mode == "defensive"
    error_message = "ALB must default to defensive desync mitigation."
  }
}

run "internet_facing_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name            = "test-alb"
      subnets         = ["subnet-aaaa", "subnet-bbbb"]
      security_groups = ["sg-aaaa"]
      internal        = false
      # allow_internet_facing intentionally left at its false default
    }
  }

  expect_failures = [
    aws_lb.this,
  ]
}

run "load_balancer_type_validation_rejects_unknown" {
  command = plan

  variables {
    config = {
      name               = "test-alb"
      subnets            = ["subnet-aaaa", "subnet-bbbb"]
      security_groups    = ["sg-aaaa"]
      load_balancer_type = "potato"
    }
  }

  expect_failures = [
    var.config,
  ]
}
