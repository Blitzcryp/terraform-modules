# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults_no_auto_egress" {
  command = plan

  variables {
    config = {
      name   = "test-sg"
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          description = "HTTPS from within the VPC"
          ip_protocol = "tcp"
          from_port   = 443
          to_port     = 443
          cidr_ipv4   = "10.0.0.0/16"
        },
      ]
      # egress_rules intentionally omitted (defaults to []).
    }
  }

  # The SG declares an empty egress list, so AWS's implicit allow-all egress
  # is stripped (PCI DSS Req 1).
  assert {
    condition     = length(aws_security_group.this.egress) == 0
    error_message = "Security group must not add any automatic egress rule."
  }

  # No egress rule resources are created when egress_rules is empty.
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 0
    error_message = "No egress rules should be created when egress_rules is empty."
  }

  # The one declared ingress rule is created.
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 1
    error_message = "Expected exactly one ingress rule to be created."
  }
}

run "public_ssh_ingress_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name   = "test-sg"
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          description = "SSH from anywhere"
          ip_protocol = "tcp"
          from_port   = 22
          to_port     = 22
          cidr_ipv4   = "0.0.0.0/0"
        },
      ]
      # allow_public_admin_ports and allow_public_ingress intentionally false.
    }
  }

  expect_failures = [
    aws_security_group.this,
  ]
}

run "rule_without_description_is_rejected" {
  command = plan

  variables {
    config = {
      name   = "test-sg"
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          description = ""
          ip_protocol = "tcp"
          from_port   = 443
          to_port     = 443
          cidr_ipv4   = "10.0.0.0/16"
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
