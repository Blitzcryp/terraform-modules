# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default composition. Child
# modules expose only their `manifest` (not their `config`), and ARNs/IDs are
# unknown under a mock provider — so assertions target known/derived values:
# child-module instance counts (which prove the conditional wiring), the
# component's own derived locals, manifest nullness, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name       = "test-shared"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

      allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allowed_cidrs              = ["10.0.0.0/16"]
    }
  }

  # No BYO key supplied => the component self-provisions a KMS key.
  assert {
    condition     = length(module.kms) == 1
    error_message = "A dedicated KMS key must be created when no BYO key is supplied."
  }

  # Exactly one file system and one mount-target security group.
  assert {
    condition     = length(module.file_system) == 1 && length(module.security_group) == 1
    error_message = "Component must compose exactly one file system and one security group."
  }

  # One mount target per subnet.
  assert {
    condition     = length(module.mount_target) == 2
    error_message = "Exactly one mount target must be created per supplied subnet."
  }

  # No access points when none are supplied.
  assert {
    condition     = length(module.access_point) == 0
    error_message = "No access points must be created when none are supplied."
  }

  # One NFS ingress rule per allowed SG and one per CIDR; no public ingress.
  assert {
    condition     = length(local.ingress_rules) == 2
    error_message = "Security group must have exactly one NFS ingress rule per allowed SG/CIDR."
  }

  # NFS uses TCP 2049.
  assert {
    condition     = local.nfs_port == 2049
    error_message = "NFS port must be 2049."
  }

  # The manifest exposes the expected keys.
  assert {
    condition     = can(output.manifest.file_system_id) && can(output.manifest.file_system_arn) && can(output.manifest.dns_name) && can(output.manifest.mount_target_ids) && can(output.manifest.security_group_id) && can(output.manifest.kms_key_arn) && can(output.manifest.access_point_ids)
    error_message = "manifest must expose all documented keys."
  }
}

run "byo_key_skips_kms_creation" {
  command = plan

  variables {
    config = {
      name        = "test-byo"
      vpc_id      = "vpc-0a1b2c3d4e5f60718"
      subnet_ids  = ["subnet-0a1b2c3d4e5f60001"]
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key => no KMS key is created and the manifest surfaces the BYO arn.
  assert {
    condition     = length(module.kms) == 0
    error_message = "A BYO kms_key_arn must skip self-provisioning the KMS key."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "BYO kms_key_arn must be passed through to the manifest."
  }

  # Single subnet => single mount target.
  assert {
    condition     = length(module.mount_target) == 1
    error_message = "A single subnet must yield a single mount target."
  }
}

run "access_points_are_created" {
  command = plan

  variables {
    config = {
      name       = "test-ap"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001"]
      access_points = {
        app = {
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
    }
  }

  assert {
    condition     = length(module.access_point) == 1
    error_message = "An access point must be created for each entry in config.access_points."
  }
}

# Negative case: zero subnets violates the subnet-count validation.
run "requires_at_least_one_subnet" {
  command = plan

  variables {
    config = {
      name       = "test-no-subnets"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = []
    }
  }

  expect_failures = [
    var.config,
  ]
}
