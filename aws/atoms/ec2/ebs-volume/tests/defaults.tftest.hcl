# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      availability_zone = "eu-central-1a"
    }
  }

  # Encrypted at rest by default (PCI DSS Req 3).
  assert {
    condition     = aws_ebs_volume.this.encrypted == true
    error_message = "EBS volume must be encrypted by default."
  }

  # Defaults to 20 GiB gp3.
  assert {
    condition     = aws_ebs_volume.this.type == "gp3" && aws_ebs_volume.this.size == 20
    error_message = "EBS volume must default to 20 GiB gp3."
  }
}

run "unencrypted_allowed_via_escape_hatch" {
  command = plan

  variables {
    config = {
      availability_zone = "eu-central-1a"
      encrypted         = false
      allow_unencrypted = true
    }
  }

  # allow_unencrypted only RELAXES the precondition; it must still plan cleanly.
  assert {
    condition     = aws_ebs_volume.this.encrypted == false
    error_message = "allow_unencrypted=true must produce an unencrypted volume."
  }
}

# Negative: disabling encryption WITHOUT the escape hatch fails the precondition.
run "unencrypted_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      availability_zone = "eu-central-1a"
      encrypted         = false
      # allow_unencrypted intentionally left false
    }
  }

  expect_failures = [
    aws_ebs_volume.this,
  ]
}
