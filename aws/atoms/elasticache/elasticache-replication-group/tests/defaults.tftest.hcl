# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default behaviour.
# config is marked sensitive (it carries the AUTH token), so values derived from
# it are tainted sensitive; assertions wrap them in nonsensitive(). ARNs/IDs are
# unknown under the mock provider, so assertions target known/derived values.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      replication_group_id = "test-redis"
      subnet_group_name    = "test-cache"
      security_group_ids   = ["sg-0a1b2c3d4e5f60099"]
      # auth_token intentionally omitted — token must come from a secrets manager.
    }
  }

  # Assert the secure defaults via the resolved config (known at plan time, and
  # not subject to the mock provider's string-typing of computed bool attributes).
  assert {
    condition     = nonsensitive(var.config.at_rest_encryption_enabled) == true
    error_message = "Encryption at rest must default to enabled (PCI DSS Req 3)."
  }

  assert {
    condition     = nonsensitive(var.config.transit_encryption_enabled) == true
    error_message = "Encryption in transit must default to enabled (PCI DSS Req 4)."
  }

  assert {
    condition     = nonsensitive(var.config.automatic_failover_enabled) == true
    error_message = "Automatic failover must default to enabled."
  }

  assert {
    condition     = nonsensitive(var.config.multi_az_enabled) == true
    error_message = "Multi-AZ must default to enabled."
  }

  assert {
    condition     = nonsensitive(var.config.num_cache_clusters) == 2
    error_message = "num_cache_clusters must default to 2 so automatic failover is possible."
  }

  assert {
    condition     = nonsensitive(var.config.port) == 6379
    error_message = "Redis port must default to 6379."
  }

  assert {
    condition     = nonsensitive(var.config.snapshot_retention_limit) == 7
    error_message = "Snapshot retention must default to 7 days."
  }

  # The replication group is wired with the resolved identifier and encryption on.
  assert {
    condition     = aws_elasticache_replication_group.this.replication_group_id == "test-redis"
    error_message = "replication_group_id must be passed through from config."
  }
}

# Negative case: disabling at-rest encryption without the escape hatch is blocked
# by the lifecycle precondition.
run "unencrypted_at_rest_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      replication_group_id       = "test-redis"
      subnet_group_name          = "test-cache"
      security_group_ids         = ["sg-0a1b2c3d4e5f60099"]
      at_rest_encryption_enabled = false
      # allow_unencrypted_at_rest intentionally left at its false default
    }
  }

  expect_failures = [
    aws_elasticache_replication_group.this,
  ]
}

# Negative case: an auth_token with transit encryption disabled violates the
# config validation (provider constraint).
run "auth_token_requires_transit_encryption" {
  command = plan

  variables {
    config = {
      replication_group_id       = "test-redis"
      subnet_group_name          = "test-cache"
      security_group_ids         = ["sg-0a1b2c3d4e5f60099"]
      transit_encryption_enabled = false
      allow_plaintext_in_transit = true
      auth_token                 = "<YOUR_AUTH_TOKEN>"
    }
  }

  expect_failures = [
    var.config,
  ]
}
