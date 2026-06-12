# Native `terraform test`. Uses a mocked AWS provider. IDs are unknown under the
# mock provider, so assertions target known/derived inputs and manifest shape.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      file_system_id  = "fs-0a1b2c3d4e5f60718"
      subnet_id       = "subnet-0a1b2c3d4e5f60001"
      security_groups = ["sg-0a1b2c3d4e5f60099"]
    }
  }

  assert {
    condition     = aws_efs_mount_target.this.file_system_id == "fs-0a1b2c3d4e5f60718"
    error_message = "file_system_id must be passed through to the mount target."
  }

  assert {
    condition     = aws_efs_mount_target.this.subnet_id == "subnet-0a1b2c3d4e5f60001"
    error_message = "subnet_id must be passed through to the mount target."
  }

  assert {
    condition     = aws_efs_mount_target.this.security_groups == toset(["sg-0a1b2c3d4e5f60099"])
    error_message = "security_groups must be passed through to the mount target."
  }

  assert {
    condition     = can(output.manifest.id) && can(output.manifest.ip_address) && can(output.manifest.network_interface_id) && can(output.manifest.availability_zone_name)
    error_message = "manifest must expose id, ip_address, network_interface_id and availability_zone_name."
  }
}

run "invalid_ip_address_is_rejected" {
  command = plan

  variables {
    config = {
      file_system_id = "fs-0a1b2c3d4e5f60718"
      subnet_id      = "subnet-0a1b2c3d4e5f60001"
      ip_address     = "not-an-ip"
    }
  }

  expect_failures = [
    var.config,
  ]
}
