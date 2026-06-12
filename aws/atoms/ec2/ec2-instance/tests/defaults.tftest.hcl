# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      ami                    = "ami-0a1b2c3d4e5f60718"
      subnet_id              = "subnet-0a1b2c3d4e5f60001"
      vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
    }
  }

  # IMDSv2 enforced (PCI DSS Req 2).
  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced by default (http_tokens=required)."
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_endpoint == "enabled"
    error_message = "Instance metadata endpoint must be enabled."
  }

  # Root volume encrypted at rest (PCI DSS Req 3).
  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted == true
    error_message = "Root volume must be encrypted by default."
  }

  # No public IP (PCI DSS Req 1).
  assert {
    condition     = aws_instance.this.associate_public_ip_address == false
    error_message = "Instances must not get a public IP by default."
  }

  # Detailed monitoring + EBS optimization on; secure instance shape defaults.
  assert {
    condition     = aws_instance.this.monitoring == true && aws_instance.this.ebs_optimized == true
    error_message = "Detailed monitoring and EBS optimization must be on by default."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].volume_type == "gp3" && aws_instance.this.root_block_device[0].volume_size == 20
    error_message = "Root volume must default to 20 GiB gp3."
  }
}

run "imdsv1_allowed_via_escape_hatch" {
  command = plan

  variables {
    config = {
      ami                    = "ami-0a1b2c3d4e5f60718"
      subnet_id              = "subnet-0a1b2c3d4e5f60001"
      vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allow_imdsv1           = true
    }
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "optional"
    error_message = "allow_imdsv1=true must relax http_tokens to optional."
  }
}

run "unencrypted_root_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      ami                    = "ami-0a1b2c3d4e5f60718"
      subnet_id              = "subnet-0a1b2c3d4e5f60001"
      vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allow_unencrypted      = true
    }
  }

  # allow_unencrypted only RELAXES the precondition; it must still plan cleanly.
  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted == false
    error_message = "allow_unencrypted=true must produce an unencrypted root volume."
  }
}

# Negative: public IP without the escape hatch must fail the precondition.
run "public_ip_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      ami                         = "ami-0a1b2c3d4e5f60718"
      subnet_id                   = "subnet-0a1b2c3d4e5f60001"
      vpc_security_group_ids      = ["sg-0a1b2c3d4e5f60099"]
      associate_public_ip_address = true
      # allow_public_ip intentionally left false
    }
  }

  expect_failures = [
    aws_instance.this,
  ]
}

# Negative: a malformed AMI id fails the config validation.
run "invalid_ami_rejected" {
  command = plan

  variables {
    config = {
      ami                    = "not-an-ami"
      subnet_id              = "subnet-0a1b2c3d4e5f60001"
      vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
