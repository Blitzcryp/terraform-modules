# Native `terraform test`. Uses a mocked AWS provider. ARNs are unknown under the
# mock provider, so assertions target known/derived inputs and manifest shape.

mock_provider "aws" {}

run "defaults" {
  command = plan

  variables {
    config = {
      file_system_id = "fs-0a1b2c3d4e5f60718"

      posix_user = {
        uid = 1000
        gid = 1000
      }

      root_directory = {
        path = "/app-data"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "0750"
        }
      }
    }
  }

  assert {
    condition     = aws_efs_access_point.this.file_system_id == "fs-0a1b2c3d4e5f60718"
    error_message = "file_system_id must be passed through to the access point."
  }

  assert {
    condition     = one(aws_efs_access_point.this.posix_user).uid == 1000
    error_message = "posix_user.uid must be passed through."
  }

  assert {
    condition     = one(aws_efs_access_point.this.root_directory).path == "/app-data"
    error_message = "root_directory.path must be passed through."
  }

  assert {
    condition     = can(output.manifest.id) && can(output.manifest.arn)
    error_message = "manifest must expose id and arn."
  }
}

run "minimal_no_posix_no_root" {
  command = plan

  variables {
    config = {
      file_system_id = "fs-0a1b2c3d4e5f60718"
    }
  }

  assert {
    condition     = length(aws_efs_access_point.this.posix_user) == 0 && length(aws_efs_access_point.this.root_directory) == 0
    error_message = "With no posix_user/root_directory supplied, neither block must be emitted."
  }
}

run "invalid_permissions_are_rejected" {
  command = plan

  variables {
    config = {
      file_system_id = "fs-0a1b2c3d4e5f60718"
      root_directory = {
        path = "/app-data"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "rwxr-x"
        }
      }
    }
  }

  expect_failures = [
    var.config,
  ]
}
