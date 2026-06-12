# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default composition.
# Child modules expose only their `manifest` (not their `config`), and ARNs/IDs
# are unknown under a mock provider — so assertions target known/derived values:
# child-module instance counts (which prove the conditional wiring), the
# component's own derived locals, manifest nullness, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name      = "test-app"
      ami       = "ami-0a1b2c3d4e5f60718"
      vpc_id    = "vpc-0a1b2c3d4e5f60718"
      subnet_id = "subnet-0a1b2c3d4e5f60001"

      allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allowed_cidrs              = ["10.0.0.0/16"]
    }
  }

  # No BYO key supplied => the component self-provisions a KMS key.
  assert {
    condition     = length(module.kms) == 1
    error_message = "A dedicated KMS key must be created when no BYO key is supplied."
  }

  # Security group, role, and instance profile are each composed exactly once.
  assert {
    condition     = length(module.security_group) == 1 && length(module.role) == 1 && length(module.instance_profile) == 1
    error_message = "Component must compose exactly one security-group, role, and instance-profile."
  }

  # One ingress rule per allowed SG and one per CIDR; no public ingress generated.
  assert {
    condition     = length(local.ingress_rules) == 2
    error_message = "Instance security group must have exactly one ingress rule per allowed SG/CIDR."
  }

  # The EC2 trust policy names only the EC2 service principal.
  assert {
    condition     = jsondecode(local.assume_role_policy).Statement[0].Principal.Service == "ec2.amazonaws.com"
    error_message = "Instance role must be assumable only by the EC2 service."
  }

  # The manifest exposes the expected keys.
  assert {
    condition     = can(output.manifest.instance_id) && can(output.manifest.instance_arn) && can(output.manifest.private_ip) && can(output.manifest.security_group_id) && can(output.manifest.role_arn) && can(output.manifest.instance_profile_arn) && can(output.manifest.kms_key_arn)
    error_message = "manifest must expose all documented keys."
  }
}

run "byo_key_skips_kms_creation" {
  command = plan

  variables {
    config = {
      name        = "test-app"
      ami         = "ami-0a1b2c3d4e5f60718"
      vpc_id      = "vpc-0a1b2c3d4e5f60718"
      subnet_id   = "subnet-0a1b2c3d4e5f60001"
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
}

# Negative: a malformed AMI id fails the config validation.
run "invalid_ami_rejected" {
  command = plan

  variables {
    config = {
      name      = "test-app"
      ami       = "not-an-ami"
      vpc_id    = "vpc-0a1b2c3d4e5f60718"
      subnet_id = "subnet-0a1b2c3d4e5f60001"
    }
  }

  expect_failures = [
    var.config,
  ]
}
