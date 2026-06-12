# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default composition.
# Child modules expose only their `manifest` (not their `config`) to tests, and
# ARNs/IDs are unknown under a mock provider — so assertions target known/derived
# values: child-module instance counts (which prove the wiring), the component's
# own derived locals, manifest nullness, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name          = "test-pg-proxy"
      vpc_id        = "vpc-0a1b2c3d4e5f60718"
      subnet_ids    = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      engine_family = "POSTGRESQL"
      secret_arns   = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:test-AbCdEf"]

      target_db_instance_identifier = "test-postgres"

      allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allowed_cidrs              = ["10.0.0.0/16"]
    }
  }

  # The proxy, its security group, and its IAM role are each composed once.
  assert {
    condition     = length(module.security_group) == 1 && length(module.role) == 1 && length(module.proxy) == 1
    error_message = "Component must compose exactly one security-group, one iam-role, and one rds-proxy."
  }

  # Engine-derived proxy port for postgresql.
  assert {
    condition     = local.proxy_port == 5432
    error_message = "PostgreSQL proxy port must be 5432."
  }

  # One ingress rule per allowed SG and one per CIDR; no public ingress generated.
  assert {
    condition     = length(local.ingress_rules) == 2
    error_message = "Proxy security group must have exactly one ingress rule per allowed SG/CIDR."
  }

  # The inline policy grants read on the supplied secret(s) and kms:Decrypt only.
  assert {
    condition     = can(regex("secretsmanager:GetSecretValue", local.secrets_policy)) && can(regex("kms:Decrypt", local.secrets_policy))
    error_message = "The proxy role must be granted secretsmanager:GetSecretValue and kms:Decrypt."
  }

  # The manifest exposes the expected keys.
  assert {
    condition     = can(output.manifest.proxy_arn) && can(output.manifest.proxy_name) && can(output.manifest.proxy_endpoint) && can(output.manifest.security_group_id) && can(output.manifest.role_arn)
    error_message = "manifest must expose all documented keys."
  }
}

run "mysql_proxy_port" {
  command = plan

  variables {
    config = {
      name          = "test-mysql-proxy"
      vpc_id        = "vpc-0a1b2c3d4e5f60718"
      subnet_ids    = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      engine_family = "MYSQL"
      secret_arns   = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:test-AbCdEf"]

      target_db_cluster_identifier = "test-mysql-cluster"
    }
  }

  assert {
    condition     = local.proxy_port == 3306
    error_message = "MySQL proxy port must be 3306."
  }
}

# Negative case: neither target set violates the exactly-one-target validation.
run "requires_exactly_one_target" {
  command = plan

  variables {
    config = {
      name          = "test-pg-proxy"
      vpc_id        = "vpc-0a1b2c3d4e5f60718"
      subnet_ids    = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      engine_family = "POSTGRESQL"
      secret_arns   = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:test-AbCdEf"]
      # neither target set => validation must fail
    }
  }

  expect_failures = [
    var.config,
  ]
}
