# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

# Give the mocked caller-identity data source a valid 12-digit account ID so the
# default-to-current-account path produces a value the provider accepts.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

run "secure_defaults" {
  command = plan

  variables {
    config = {}
  }

  assert {
    condition     = contains(aws_inspector2_enabler.this.resource_types, "ECR")
    error_message = "ECR scanning must be enabled by default (PCI DSS Req 6/11)."
  }

  assert {
    condition     = contains(aws_inspector2_enabler.this.resource_types, "EC2")
    error_message = "EC2 scanning must be enabled by default (PCI DSS Req 6/11)."
  }

  assert {
    condition     = contains(aws_inspector2_enabler.this.resource_types, "LAMBDA")
    error_message = "LAMBDA scanning must be enabled by default (PCI DSS Req 6/11)."
  }

  # account_ids defaults to the current account (non-empty).
  assert {
    condition     = length(aws_inspector2_enabler.this.account_ids) == 1
    error_message = "account_ids must default to the current account."
  }
}

run "resource_types_validation_rejects_unknown_type" {
  command = plan

  variables {
    config = {
      resource_types = ["ECR", "RDS"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
