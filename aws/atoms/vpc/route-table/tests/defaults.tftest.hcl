# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "public_table_with_route_and_association" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-00000000000000000"
      name   = "test-public-rt"
      routes = [
        {
          cidr_block = "0.0.0.0/0"
          gateway_id = "igw-00000000000000000"
        },
      ]
      subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    }
  }

  assert {
    condition     = aws_route_table.this.vpc_id == "vpc-00000000000000000"
    error_message = "Route table must belong to the supplied vpc_id."
  }

  assert {
    condition     = length(aws_route.this) == 1
    error_message = "One route must be created."
  }

  assert {
    condition     = aws_route.this["0.0.0.0/0"].gateway_id == "igw-00000000000000000"
    error_message = "Default route must target the supplied gateway."
  }

  assert {
    condition     = length(aws_route_table_association.this) == 2
    error_message = "One association must be created per subnet id."
  }

  assert {
    condition     = aws_route_table.this.tags["Module"] == "atoms/vpc/route-table"
    error_message = "Module identity tag must be present."
  }
}

run "empty_routes_and_subnets" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-00000000000000000"
    }
  }

  assert {
    condition     = length(aws_route.this) == 0 && length(aws_route_table_association.this) == 0
    error_message = "No routes or associations should be created when none are supplied."
  }
}

run "route_without_target_is_rejected" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-00000000000000000"
      routes = [
        {
          cidr_block = "0.0.0.0/0"
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "route_with_two_targets_is_rejected" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-00000000000000000"
      routes = [
        {
          cidr_block     = "0.0.0.0/0"
          gateway_id     = "igw-00000000000000000"
          nat_gateway_id = "nat-00000000000000000"
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
