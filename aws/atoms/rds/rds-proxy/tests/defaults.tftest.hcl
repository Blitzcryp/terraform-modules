# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name           = "test-pg-proxy"
      engine_family  = "POSTGRESQL"
      secret_arns    = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:test-AbCdEf"]
      role_arn       = "arn:aws:iam::111122223333:role/test-rds-proxy"
      vpc_subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

      target_db_instance_identifier = "test-postgres"
    }
  }

  assert {
    condition     = aws_db_proxy.this.require_tls == true
    error_message = "require_tls must default to true (PCI DSS Req 4)."
  }

  assert {
    condition     = one([for a in aws_db_proxy.this.auth : a.auth_scheme]) == "SECRETS"
    error_message = "auth must use the SECRETS scheme (no plaintext creds)."
  }

  assert {
    condition     = one([for a in aws_db_proxy.this.auth : a.iam_auth]) == "REQUIRED"
    error_message = "IAM auth must be required (PCI DSS Req 8)."
  }

  # The default target group and a single target are wired alongside the proxy.
  assert {
    condition     = aws_db_proxy_target.this.db_instance_identifier == "test-postgres"
    error_message = "The DB instance target must be registered with the proxy."
  }
}

run "plaintext_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name           = "test-pg-proxy"
      engine_family  = "POSTGRESQL"
      secret_arns    = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:test-AbCdEf"]
      role_arn       = "arn:aws:iam::111122223333:role/test-rds-proxy"
      vpc_subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

      target_db_instance_identifier = "test-postgres"
      require_tls                   = false
      # allow_plaintext intentionally left at its false default
    }
  }

  expect_failures = [
    aws_db_proxy.this,
  ]
}

run "requires_exactly_one_target" {
  command = plan

  variables {
    config = {
      name           = "test-pg-proxy"
      engine_family  = "POSTGRESQL"
      secret_arns    = ["arn:aws:secretsmanager:eu-central-1:111122223333:secret:test-AbCdEf"]
      role_arn       = "arn:aws:iam::111122223333:role/test-rds-proxy"
      vpc_subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      # neither target set => validation must fail
    }
  }

  expect_failures = [
    var.config,
  ]
}
