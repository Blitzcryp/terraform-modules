# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.
# The password below is a NON-REAL test placeholder (PCI DSS Req 8).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      broker_name     = "test-broker"
      subnet_ids      = ["subnet-a", "subnet-b"]
      security_groups = ["sg-a"]
      kms_key_arn     = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      users = [
        {
          username = "app-service"
          password = "<TEST_PLACEHOLDER_PASSWORD>"
        },
      ]
    }
  }

  # config is a sensitive variable, so derived attributes render as sensitive;
  # nonsensitive() is required to compare them in assertions.

  # PCI DSS Req 1: not public by default.
  assert {
    condition     = tostring(nonsensitive(aws_mq_broker.this.publicly_accessible)) == "false"
    error_message = "Broker must not be publicly accessible by default (PCI DSS Req 1)."
  }

  # PCI DSS Req 3: customer-managed CMK at rest, AWS-owned key off.
  assert {
    condition     = tostring(nonsensitive(aws_mq_broker.this.encryption_options[0].use_aws_owned_key)) == "false"
    error_message = "Must use a customer-managed KMS key, not the AWS-owned key (PCI DSS Req 3)."
  }

  assert {
    condition     = nonsensitive(aws_mq_broker.this.encryption_options[0].kms_key_id) != null
    error_message = "encryption_options.kms_key_id must be set from the provided CMK (PCI DSS Req 3)."
  }

  # PCI DSS Req 10: general + audit logging on (ActiveMQ default).
  assert {
    condition     = tostring(nonsensitive(aws_mq_broker.this.logs[0].general)) == "true"
    error_message = "General logging must be enabled by default (PCI DSS Req 10)."
  }

  assert {
    condition     = tostring(nonsensitive(aws_mq_broker.this.logs[0].audit)) == "true"
    error_message = "Audit logging must be enabled by default for ActiveMQ (PCI DSS Req 10)."
  }
}

run "rabbitmq_drops_audit_logging" {
  command = plan

  variables {
    config = {
      broker_name     = "test-broker"
      engine_type     = "RabbitMQ"
      deployment_mode = "CLUSTER_MULTI_AZ"
      subnet_ids      = ["subnet-a", "subnet-b"]
      security_groups = ["sg-a"]
      kms_key_arn     = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      users = [
        {
          username = "app-service"
          password = "<TEST_PLACEHOLDER_PASSWORD>"
        },
      ]
    }
  }

  # Audit logging is invalid for RabbitMQ; the module must guard it to false.
  assert {
    condition     = tostring(nonsensitive(aws_mq_broker.this.logs[0].audit)) == "false"
    error_message = "Audit logging must be disabled for RabbitMQ (unsupported by the engine)."
  }
}

run "public_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      broker_name         = "test-broker"
      subnet_ids          = ["subnet-a", "subnet-b"]
      security_groups     = ["sg-a"]
      kms_key_arn         = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      publicly_accessible = true
      # allow_public intentionally left at its false default
      users = [
        {
          username = "app-service"
          password = "<TEST_PLACEHOLDER_PASSWORD>"
        },
      ]
    }
  }

  expect_failures = [
    aws_mq_broker.this,
  ]
}

run "invalid_engine_type_fails_validation" {
  command = plan

  variables {
    config = {
      broker_name     = "test-broker"
      engine_type     = "Kafka"
      subnet_ids      = ["subnet-a", "subnet-b"]
      security_groups = ["sg-a"]
      kms_key_arn     = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"
      users = [
        {
          username = "app-service"
          password = "<TEST_PLACEHOLDER_PASSWORD>"
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
