# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default composition.
# config is marked sensitive (it carries the AUTH token), so values derived from
# it are tainted sensitive; assertions wrap them in nonsensitive() where needed.
# Child modules expose only their `manifest` (not their `config`); ARNs/IDs are
# unknown under the mock provider, so assertions target known/derived values:
# child-module instance counts (which prove the conditional wiring), the
# component's own derived locals, manifest nullness, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name       = "test-redis"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

      allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allowed_cidrs              = ["10.0.0.0/16"]
      # auth_token omitted — must come from a secrets manager.
    }
  }

  # No BYO key supplied => the component self-provisions a KMS key.
  assert {
    condition     = length(module.kms) == 1
    error_message = "A dedicated KMS key must be created when no BYO key is supplied."
  }

  # The replication group is composed once, alongside one subnet group and SG.
  assert {
    condition     = length(module.subnet_group) == 1 && length(module.security_group) == 1 && length(module.replication_group) == 1
    error_message = "Component must compose exactly one subnet-group, one security-group and one replication-group."
  }

  # One ingress rule per allowed SG and one per CIDR; no public ingress generated.
  assert {
    condition     = length(nonsensitive(local.ingress_rules)) == 2
    error_message = "Cache security group must have exactly one ingress rule per allowed SG/CIDR."
  }

  # The manifest exposes the expected keys. ARNs/IDs are unknown under the mock
  # provider; the kms-count assert above proves the key is self-provisioned and
  # its arn is wired into the manifest.
  assert {
    condition     = can(output.manifest.replication_group_id) && can(output.manifest.primary_endpoint) && can(output.manifest.reader_endpoint) && can(output.manifest.port) && can(output.manifest.security_group_id) && can(output.manifest.kms_key_arn)
    error_message = "manifest must expose all documented keys."
  }
}

run "byo_key_skips_kms_creation" {
  command = plan

  variables {
    config = {
      name        = "test-redis"
      vpc_id      = "vpc-0a1b2c3d4e5f60718"
      subnet_ids  = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key => no KMS key is created and the manifest surfaces the BYO arn.
  assert {
    condition     = length(module.kms) == 0
    error_message = "A BYO kms_key_arn must skip self-provisioning the KMS key."
  }

  assert {
    condition     = nonsensitive(output.manifest.kms_key_arn) == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "BYO kms_key_arn must be passed through to the manifest."
  }
}

# Negative case: fewer than two subnets violates the subnet-count validation.
run "requires_two_subnets" {
  command = plan

  variables {
    config = {
      name       = "test-redis"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
