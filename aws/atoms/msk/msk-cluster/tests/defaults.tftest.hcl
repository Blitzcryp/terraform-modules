# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      cluster_name              = "test-events"
      client_subnets            = ["subnet-a", "subnet-b", "subnet-c"]
      security_groups           = ["sg-a"]
      kms_key_arn               = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      cloudwatch_log_group_name = "/aws/msk/test-events"
    }
  }

  # PCI DSS Req 4: in-transit must be TLS by default.
  assert {
    condition     = aws_msk_cluster.this.encryption_info[0].encryption_in_transit[0].client_broker == "TLS"
    error_message = "client_broker must default to TLS (PCI DSS Req 4)."
  }

  assert {
    condition     = aws_msk_cluster.this.encryption_info[0].encryption_in_transit[0].in_cluster == true
    error_message = "in-cluster encryption must default to enabled (PCI DSS Req 4)."
  }

  # PCI DSS Req 3: at-rest with a customer-managed CMK.
  assert {
    condition     = aws_msk_cluster.this.encryption_info[0].encryption_at_rest_kms_key_arn != null
    error_message = "Encryption at rest must use the provided customer-managed KMS key (PCI DSS Req 3)."
  }

  # Default auth = SASL/IAM.
  assert {
    condition     = aws_msk_cluster.this.client_authentication[0].sasl[0].iam == true
    error_message = "SASL/IAM client authentication must be enabled by default."
  }

  # PCI DSS Req 10: broker logging on when a log group is provided.
  assert {
    condition     = aws_msk_cluster.this.logging_info[0].broker_logs[0].cloudwatch_logs[0].enabled == true
    error_message = "Broker logging to CloudWatch must be enabled when a log group is provided (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_msk_cluster.this.enhanced_monitoring == "PER_TOPIC_PER_BROKER"
    error_message = "enhanced_monitoring must default to PER_TOPIC_PER_BROKER."
  }
}

run "plaintext_in_transit_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      cluster_name                        = "test-events"
      client_subnets                      = ["subnet-a", "subnet-b", "subnet-c"]
      security_groups                     = ["sg-a"]
      kms_key_arn                         = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      cloudwatch_log_group_name           = "/aws/msk/test-events"
      encryption_in_transit_client_broker = "PLAINTEXT"
      # allow_plaintext_in_transit intentionally left at its false default
    }
  }

  expect_failures = [
    aws_msk_cluster.this,
  ]
}

run "no_auth_method_fails_validation" {
  command = plan

  variables {
    config = {
      cluster_name              = "test-events"
      client_subnets            = ["subnet-a", "subnet-b", "subnet-c"]
      security_groups           = ["sg-a"]
      kms_key_arn               = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      cloudwatch_log_group_name = "/aws/msk/test-events"
      sasl_iam_enabled          = false
    }
  }

  expect_failures = [
    var.config,
  ]
}
