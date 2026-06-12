# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "attaches_to_vpc" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-00000000000000000"
      name   = "test-igw"
    }
  }

  assert {
    condition     = aws_internet_gateway.this.vpc_id == "vpc-00000000000000000"
    error_message = "Internet gateway must attach to the supplied vpc_id."
  }

  assert {
    condition     = aws_internet_gateway.this.tags["Name"] == "test-igw"
    error_message = "Name tag must be set from config.name."
  }

  assert {
    condition     = aws_internet_gateway.this.tags["Module"] == "atoms/vpc/internet-gateway"
    error_message = "Module identity tag must be present."
  }
}

run "name_optional" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-00000000000000000"
    }
  }

  assert {
    condition     = !can(aws_internet_gateway.this.tags["Name"])
    error_message = "No Name tag should be set when config.name is null."
  }
}
