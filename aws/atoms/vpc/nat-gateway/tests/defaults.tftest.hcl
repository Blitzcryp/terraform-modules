# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "public_nat_defaults" {
  command = plan

  variables {
    config = {
      subnet_id     = "subnet-00000000000000000"
      allocation_id = "eipalloc-00000000000000000"
      name          = "test-nat"
    }
  }

  assert {
    condition     = aws_nat_gateway.this.connectivity_type == "public"
    error_message = "NAT gateway must default to public connectivity."
  }

  assert {
    condition     = aws_nat_gateway.this.subnet_id == "subnet-00000000000000000"
    error_message = "NAT gateway must live in the supplied subnet."
  }

  assert {
    condition     = aws_nat_gateway.this.allocation_id == "eipalloc-00000000000000000"
    error_message = "Public NAT gateway must attach the supplied EIP allocation."
  }

  assert {
    condition     = aws_nat_gateway.this.tags["Module"] == "atoms/vpc/nat-gateway"
    error_message = "Module identity tag must be present."
  }
}

run "private_nat_drops_allocation" {
  command = plan

  variables {
    config = {
      subnet_id         = "subnet-00000000000000000"
      allocation_id     = "eipalloc-00000000000000000"
      connectivity_type = "private"
    }
  }

  assert {
    condition     = aws_nat_gateway.this.allocation_id == null
    error_message = "Private NAT gateway must not attach an EIP allocation."
  }
}

run "rejects_invalid_connectivity_type" {
  command = plan

  variables {
    config = {
      subnet_id         = "subnet-00000000000000000"
      allocation_id     = "eipalloc-00000000000000000"
      connectivity_type = "hybrid"
    }
  }

  expect_failures = [
    var.config,
  ]
}
