# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed. ARNs are unknown under the mock provider, so
# assertions target known/derived values.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      name       = "test-cache"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
    }
  }

  assert {
    condition     = aws_elasticache_subnet_group.this.name == "test-cache"
    error_message = "Subnet group name must be passed through from config."
  }

  assert {
    condition     = length(aws_elasticache_subnet_group.this.subnet_ids) == 2
    error_message = "Both supplied subnet IDs must be attached to the subnet group."
  }
}

# Negative case: fewer than two subnets violates the subnet-count validation.
run "requires_two_subnets" {
  command = plan

  variables {
    config = {
      name       = "test-cache"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
