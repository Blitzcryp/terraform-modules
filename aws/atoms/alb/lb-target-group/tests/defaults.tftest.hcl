# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name   = "test-tg"
      port   = 443
      vpc_id = "vpc-aaaa"
    }
  }

  assert {
    condition     = aws_lb_target_group.this.protocol == "HTTPS"
    error_message = "Target group must default to HTTPS (encrypted) traffic (PCI DSS Req 4)."
  }

  assert {
    condition     = aws_lb_target_group.this.target_type == "ip"
    error_message = "Target group must default to target_type=ip."
  }

  assert {
    condition     = aws_lb_target_group.this.health_check[0].protocol == "HTTPS"
    error_message = "Health check must default to HTTPS."
  }
}

run "protocol_validation_rejects_non_http" {
  command = plan

  variables {
    config = {
      name     = "test-tg"
      port     = 443
      vpc_id   = "vpc-aaaa"
      protocol = "TCP"
    }
  }

  expect_failures = [
    var.config,
  ]
}
