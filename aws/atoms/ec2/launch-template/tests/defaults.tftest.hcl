# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name                   = "test-app"
      image_id               = "ami-0a1b2c3d4e5f60718"
      vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
    }
  }

  # IMDSv2 enforced (PCI DSS Req 2).
  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced by default (http_tokens=required)."
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_endpoint == "enabled"
    error_message = "Instance metadata endpoint must be enabled."
  }

  # Root volume encrypted at rest (PCI DSS Req 3).
  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "Root volume must be encrypted by default."
  }

  # Detailed monitoring on (PCI DSS Req 10).
  assert {
    condition     = aws_launch_template.this.monitoring[0].enabled == true
    error_message = "Detailed monitoring must be on by default."
  }

  # Root volume defaults to 20 GiB gp3.
  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].ebs[0].volume_type == "gp3" && aws_launch_template.this.block_device_mappings[0].ebs[0].volume_size == 20
    error_message = "Root volume must default to 20 GiB gp3."
  }
}

run "imdsv1_allowed_via_escape_hatch" {
  command = plan

  variables {
    config = {
      name         = "test-app"
      image_id     = "ami-0a1b2c3d4e5f60718"
      allow_imdsv1 = true
    }
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "optional"
    error_message = "allow_imdsv1=true must relax http_tokens to optional."
  }
}

run "unencrypted_root_allowed_via_escape_hatch" {
  command = plan

  variables {
    config = {
      name              = "test-app"
      image_id          = "ami-0a1b2c3d4e5f60718"
      allow_unencrypted = true
    }
  }

  # allow_unencrypted only RELAXES the precondition; it must still plan cleanly.
  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted == "false"
    error_message = "allow_unencrypted=true must produce an unencrypted root volume."
  }
}

# Negative: a malformed AMI id fails the config validation.
run "invalid_image_id_rejected" {
  command = plan

  variables {
    config = {
      name     = "test-app"
      image_id = "not-an-ami"
    }
  }

  expect_failures = [
    var.config,
  ]
}
