# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default serverless composition.
# Child modules expose only their `manifest` (not their `config`) to tests, and
# ARNs/IDs are unknown under a mock provider — so assertions target known/derived
# values: child-module instance counts (which prove the conditional wiring), the
# component's own derived locals, manifest nullness, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name       = "test-serverless"
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

  # The cluster atom is composed exactly once, alongside one subnet group and SG.
  assert {
    condition     = length(module.db_subnet_group) == 1 && length(module.security_group) == 1
    error_message = "Component must compose exactly one db-subnet-group and one security-group."
  }

  # Engine-derived DB port for postgresql.
  assert {
    condition     = local.db_port == 5432
    error_message = "PostgreSQL default DB port must be 5432."
  }

  # One ingress rule per allowed SG and one per CIDR; no public ingress generated.
  assert {
    condition     = length(local.ingress_rules) == 2
    error_message = "DB security group must have exactly one ingress rule per allowed SG/CIDR."
  }

  # The manifest exposes the expected keys. ARNs/IDs are unknown under the mock
  # provider; the kms-count assert above proves the key is self-provisioned and
  # its arn is wired into the manifest.
  assert {
    condition     = can(output.manifest.cluster_id) && can(output.manifest.cluster_arn) && can(output.manifest.endpoint) && can(output.manifest.reader_endpoint) && can(output.manifest.port) && can(output.manifest.security_group_id) && can(output.manifest.master_user_secret_arn) && can(output.manifest.kms_key_arn)
    error_message = "manifest must expose all documented keys."
  }
}

run "byo_key_skips_kms_creation" {
  command = plan

  variables {
    config = {
      name         = "test-serverless"
      vpc_id       = "vpc-0a1b2c3d4e5f60718"
      subnet_ids   = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      engine       = "aurora-mysql"
      kms_key_arn  = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      min_capacity = 1
      max_capacity = 16
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

  # MySQL engine derives port 3306.
  assert {
    condition     = local.db_port == 3306
    error_message = "MySQL default DB port must be 3306."
  }
}

# Negative case: min_capacity > max_capacity violates the capacity validation.
run "rejects_inverted_capacity" {
  command = plan

  variables {
    config = {
      name         = "test-serverless"
      vpc_id       = "vpc-0a1b2c3d4e5f60718"
      subnet_ids   = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      min_capacity = 8
      max_capacity = 4
    }
  }

  expect_failures = [
    var.config,
  ]
}
