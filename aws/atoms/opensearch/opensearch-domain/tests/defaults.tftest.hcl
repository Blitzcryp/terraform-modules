# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the OpenSearch domain's secure-by-default
# behaviour. ARNs are unknown under the mock provider, so assertions target
# known/derived config values and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      domain_name = "test-logs"
    }
  }

  # Encryption at rest on by default (PCI DSS Req 3).
  assert {
    condition     = aws_opensearch_domain.this.encrypt_at_rest[0].enabled == true
    error_message = "Encryption at rest must default to enabled (PCI DSS Req 3)."
  }

  # Node-to-node encryption on by default (PCI DSS Req 4).
  assert {
    condition     = aws_opensearch_domain.this.node_to_node_encryption[0].enabled == true
    error_message = "Node-to-node encryption must default to enabled (PCI DSS Req 4)."
  }

  # HTTPS enforced on TLS 1.2 (PCI DSS Req 4).
  assert {
    condition     = aws_opensearch_domain.this.domain_endpoint_options[0].enforce_https == true
    error_message = "HTTPS must be enforced by default."
  }

  assert {
    condition     = aws_opensearch_domain.this.domain_endpoint_options[0].tls_security_policy == "Policy-Min-TLS-1-2-2019-07"
    error_message = "TLS policy must default to Policy-Min-TLS-1-2-2019-07."
  }

  # Fine-grained access control on, internal user database off (no stored password).
  assert {
    condition     = aws_opensearch_domain.this.advanced_security_options[0].enabled == true
    error_message = "Fine-grained access control must default to enabled (PCI DSS Req 7/8)."
  }

  assert {
    condition     = aws_opensearch_domain.this.advanced_security_options[0].internal_user_database_enabled == false
    error_message = "Internal user database must be disabled (IAM master user only — no stored password)."
  }

  # Default sizing and engine.
  assert {
    condition     = aws_opensearch_domain.this.engine_version == "OpenSearch_2.11"
    error_message = "engine_version must default to OpenSearch_2.11."
  }

  assert {
    condition     = aws_opensearch_domain.this.cluster_config[0].zone_awareness_enabled == true
    error_message = "Zone awareness must default to enabled."
  }
}

run "byo_kms_and_vpc_placement" {
  command = plan

  variables {
    config = {
      domain_name            = "test-vpc"
      kms_key_arn            = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      vpc_subnet_ids         = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
    }
  }

  # BYO key wired into encrypt_at_rest.
  assert {
    condition     = aws_opensearch_domain.this.encrypt_at_rest[0].kms_key_id == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "BYO kms_key_arn must be wired into encrypt_at_rest.kms_key_id."
  }

  # Supplying subnets places the domain inside the VPC (no public endpoint).
  assert {
    condition     = length(aws_opensearch_domain.this.vpc_options) == 1
    error_message = "Supplying vpc_subnet_ids must place the domain inside the VPC."
  }
}

run "log_delivery_publishes_all_log_types" {
  command = plan

  variables {
    config = {
      domain_name              = "test-logged"
      cloudwatch_log_group_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/aws/opensearch/test-logged"
    }
  }

  # Audit + error + search/index slow logs => four log_publishing_options blocks.
  assert {
    condition     = length(aws_opensearch_domain.this.log_publishing_options) == 4
    error_message = "All four log types (audit/error/search-slow/index-slow) must be published when a log group is supplied."
  }
}

# Negative case: disabling encryption at rest without the escape hatch is blocked
# by the resource lifecycle precondition.
run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      domain_name     = "test-unenc"
      encrypt_at_rest = false
      # allow_unencrypted intentionally left at its false default
    }
  }

  expect_failures = [
    aws_opensearch_domain.this,
  ]
}

# Negative case: an invalid domain name is rejected by config validation.
run "invalid_domain_name_is_rejected" {
  command = plan

  variables {
    config = {
      domain_name = "Bad_Name"
    }
  }

  expect_failures = [
    var.config,
  ]
}
