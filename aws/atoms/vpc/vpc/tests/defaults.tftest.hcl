# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name                     = "test-vpc"
      cidr_block               = "10.0.0.0/16"
      flow_log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/vpc/flow-logs:*"
      flow_log_iam_role_arn    = "arn:aws:iam::111122223333:role/vpc-flow-logs-delivery"
    }
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "enable_dns_support must default to true."
  }

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "enable_dns_hostnames must default to true."
  }

  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0
    error_message = "Default security group must have NO ingress rules (PCI DSS Req 1 / CIS)."
  }

  assert {
    condition     = length(aws_default_security_group.this.egress) == 0
    error_message = "Default security group must have NO egress rules (PCI DSS Req 1 / CIS)."
  }

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "VPC Flow Logs must be enabled by default (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "Flow logs must capture ALL traffic by default."
  }
}

run "flow_logs_disabled_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name       = "test-vpc"
      cidr_block = "10.0.0.0/16"
      # destination/role not needed because flow logs are off
      enable_flow_logs = false
      # allow_flow_logs_disabled intentionally left false
    }
  }

  expect_failures = [
    aws_vpc.this,
  ]
}

run "missing_destination_is_blocked" {
  command = plan

  variables {
    config = {
      name       = "test-vpc"
      cidr_block = "10.0.0.0/16"
      # enable_flow_logs defaults true but no destination ARN supplied
    }
  }

  expect_failures = [
    aws_vpc.this,
  ]
}

run "invalid_cidr_is_rejected" {
  command = plan

  variables {
    config = {
      name       = "test-vpc"
      cidr_block = "not-a-cidr"
    }
  }

  expect_failures = [
    var.config,
  ]
}
