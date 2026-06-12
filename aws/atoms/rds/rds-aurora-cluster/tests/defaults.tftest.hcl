# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      cluster_identifier     = "test-aurora"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
    }
  }

  assert {
    condition     = aws_rds_cluster.this.storage_encrypted == true
    error_message = "storage_encrypted must default to true (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_rds_cluster.this.deletion_protection == true
    error_message = "deletion_protection must default to true."
  }

  assert {
    condition     = aws_rds_cluster.this.backup_retention_period == 14
    error_message = "backup_retention_period must default to 14 (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_rds_cluster.this.iam_database_authentication_enabled == true
    error_message = "iam_database_authentication_enabled must default to true (PCI DSS Req 8)."
  }

  assert {
    condition     = aws_rds_cluster.this.manage_master_user_password == true
    error_message = "manage_master_user_password must default to true (no plaintext creds)."
  }

  assert {
    condition     = contains(aws_rds_cluster.this.enabled_cloudwatch_logs_exports, "postgresql")
    error_message = "postgresql logs must be exported by default for aurora-postgresql (PCI DSS Req 10)."
  }

  assert {
    condition     = length(aws_rds_cluster_instance.this) == 2
    error_message = "instance_count must default to 2."
  }
}

run "mysql_default_logs" {
  command = plan

  variables {
    config = {
      cluster_identifier     = "test-aurora-mysql"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
      engine                 = "aurora-mysql"
    }
  }

  assert {
    condition     = contains(aws_rds_cluster.this.enabled_cloudwatch_logs_exports, "audit")
    error_message = "aurora-mysql must export the audit log by default (PCI DSS Req 10)."
  }
}

run "serverless_v2_forces_db_serverless" {
  command = plan

  variables {
    config = {
      cluster_identifier     = "test-aurora-sv2"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
      serverlessv2_scaling_configuration = {
        min_capacity = 0.5
        max_capacity = 4
      }
    }
  }

  assert {
    condition     = aws_rds_cluster_instance.this[0].instance_class == "db.serverless"
    error_message = "Setting serverlessv2_scaling_configuration must force instance_class=db.serverless."
  }
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      cluster_identifier     = "test-aurora"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
      storage_encrypted      = false
      # allow_unencrypted intentionally left at its false default
    }
  }

  expect_failures = [
    aws_rds_cluster.this,
  ]
}

run "deletion_unprotected_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      cluster_identifier     = "test-aurora"
      db_subnet_group_name   = "test-subnet-group"
      vpc_security_group_ids = ["sg-00000000000000000"]
      deletion_protection    = false
      # allow_deletion intentionally left at its false default
    }
  }

  expect_failures = [
    aws_rds_cluster.this,
  ]
}

run "backup_retention_validation_rejects_out_of_range" {
  command = plan

  variables {
    config = {
      cluster_identifier      = "test-aurora"
      db_subnet_group_name    = "test-subnet-group"
      vpc_security_group_ids  = ["sg-00000000000000000"]
      backup_retention_period = 3
    }
  }

  expect_failures = [
    var.config,
  ]
}
