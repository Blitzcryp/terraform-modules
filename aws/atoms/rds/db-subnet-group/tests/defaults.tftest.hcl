# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "creates_subnet_group" {
  command = plan

  variables {
    config = {
      name = "test-db-subnet-group"
      subnet_ids = [
        "subnet-00000000000000001",
        "subnet-00000000000000002",
      ]
    }
  }

  assert {
    condition     = aws_db_subnet_group.this.name == "test-db-subnet-group"
    error_message = "name must be passed through to the resource."
  }

  assert {
    condition     = length(aws_db_subnet_group.this.subnet_ids) == 2
    error_message = "subnet_ids must be passed through to the resource."
  }

  assert {
    condition     = aws_db_subnet_group.this.description == "Managed by terraform (atoms/db-subnet-group)"
    error_message = "description must default to the managed-by-terraform string."
  }
}

run "rejects_single_subnet" {
  command = plan

  variables {
    config = {
      name       = "test-db-subnet-group"
      subnet_ids = ["subnet-00000000000000001"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
