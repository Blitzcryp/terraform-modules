# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed.

mock_provider "aws" {}

run "vpc_domain_default" {
  command = plan

  variables {
    config = {
      name = "test-eip"
    }
  }

  assert {
    condition     = aws_eip.this.domain == "vpc"
    error_message = "Elastic IP must default to the 'vpc' domain."
  }

  assert {
    condition     = aws_eip.this.tags["Name"] == "test-eip"
    error_message = "Name tag must be set from config.name."
  }

  assert {
    condition     = aws_eip.this.tags["Module"] == "atoms/vpc/elastic-ip"
    error_message = "Module identity tag must be present."
  }
}

run "rejects_invalid_domain" {
  command = plan

  variables {
    config = {
      domain = "galaxy"
    }
  }

  expect_failures = [
    var.config,
  ]
}
