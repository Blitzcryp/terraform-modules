# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name              = "test-subnet"
      vpc_id            = "vpc-0123456789abcdef0"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "eu-central-1a"
    }
  }

  assert {
    condition     = aws_subnet.this.map_public_ip_on_launch == false
    error_message = "map_public_ip_on_launch must default to false (PCI DSS Req 1)."
  }
}

run "auto_public_ip_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name                    = "test-subnet"
      vpc_id                  = "vpc-0123456789abcdef0"
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "eu-central-1a"
      map_public_ip_on_launch = true
      # allow_auto_public_ip intentionally left false
    }
  }

  expect_failures = [
    aws_subnet.this,
  ]
}

run "invalid_cidr_is_rejected" {
  command = plan

  variables {
    config = {
      name              = "test-subnet"
      vpc_id            = "vpc-0123456789abcdef0"
      cidr_block        = "nope"
      availability_zone = "eu-central-1a"
    }
  }

  expect_failures = [
    var.config,
  ]
}
