# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      identifier             = "test-postgres"
      engine                 = "postgres"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
    }
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "storage_encrypted must default to true (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_db_instance.this.multi_az == true
    error_message = "multi_az must default to true."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == true
    error_message = "deletion_protection must default to true."
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "publicly_accessible must default to false (PCI DSS Req 1)."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 14
    error_message = "backup_retention_period must default to 14 (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled == true
    error_message = "iam_database_authentication_enabled must default to true (PCI DSS Req 8)."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "manage_master_user_password must default to true (no plaintext creds)."
  }

  assert {
    condition     = aws_db_instance.this.performance_insights_enabled == true
    error_message = "performance_insights_enabled must default to true (PCI DSS Req 10)."
  }

  assert {
    condition     = contains(aws_db_instance.this.enabled_cloudwatch_logs_exports, "postgresql")
    error_message = "postgresql logs must be exported by default for postgres (PCI DSS Req 10)."
  }
}

run "mysql_default_logs" {
  command = plan

  variables {
    config = {
      identifier             = "test-mysql"
      engine                 = "mysql"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
    }
  }

  assert {
    condition     = contains(aws_db_instance.this.enabled_cloudwatch_logs_exports, "audit")
    error_message = "mysql must export the audit log by default (PCI DSS Req 10)."
  }
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      identifier             = "test-postgres"
      engine                 = "postgres"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
      storage_encrypted      = false
      # allow_unencrypted intentionally left at its false default
    }
  }

  expect_failures = [
    aws_db_instance.this,
  ]
}

run "public_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      identifier             = "test-postgres"
      engine                 = "postgres"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
      publicly_accessible    = true
      # allow_public intentionally left at its false default
    }
  }

  expect_failures = [
    aws_db_instance.this,
  ]
}

run "backup_retention_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      identifier              = "test-postgres"
      engine                  = "postgres"
      db_subnet_group_name    = "test-subnet-group"
      vpc_security_group_ids  = ["sg-00000000000000000"]
      backup_retention_period = 3
    }
  }

  expect_failures = [
    var.config,
  ]
}
