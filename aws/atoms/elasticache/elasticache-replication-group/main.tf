locals {
  module_tags = {
    Module = "atoms/elasticache/elasticache-replication-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_elasticache_replication_group" "this" {
  # checkov:skip=CKV_AWS_29: at_rest_encryption_enabled defaults true via config (optional(bool, true));
  # checkov:skip=CKV_AWS_30: transit_encryption_enabled defaults true; checkov cannot statically
  # resolve these values through the config object, but the secure defaults are enforced by the
  # secure_defaults test and the lifecycle preconditions. Relaxing encryption requires the auditable
  # config.allow_unencrypted_at_rest / config.allow_plaintext_in_transit escape hatches (PCI DSS Req 3/4).
  replication_group_id = var.config.replication_group_id
  description          = var.config.description

  engine               = var.config.engine
  engine_version       = var.config.engine_version
  node_type            = var.config.node_type
  port                 = var.config.port
  parameter_group_name = var.config.parameter_group_name

  subnet_group_name  = var.config.subnet_group_name
  security_group_ids = var.config.security_group_ids

  automatic_failover_enabled = var.config.automatic_failover_enabled
  multi_az_enabled           = var.config.multi_az_enabled
  num_cache_clusters         = var.config.num_cache_clusters
  snapshot_retention_limit   = var.config.snapshot_retention_limit

  # Encryption at rest (PCI DSS Req 3). kms_key_id only takes effect when at-rest
  # encryption is on; null = AWS-managed key.
  at_rest_encryption_enabled = var.config.at_rest_encryption_enabled
  kms_key_id                 = var.config.at_rest_encryption_enabled ? var.config.kms_key_arn : null

  # Encryption in transit (PCI DSS Req 4).
  transit_encryption_enabled = var.config.transit_encryption_enabled

  # Access control (PCI DSS Req 8). SECURITY: the AUTH token must originate from a
  # secrets manager — never a literal in source. Only valid when transit is on.
  auth_token = var.config.auth_token

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = var.config.at_rest_encryption_enabled || var.config.allow_unencrypted_at_rest
      error_message = "Encryption at rest disabled without config.allow_unencrypted_at_rest=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # Encryption in transit must be intentional to weaken (PCI DSS Req 4).
    precondition {
      condition     = var.config.transit_encryption_enabled || var.config.allow_plaintext_in_transit
      error_message = "Encryption in transit disabled without config.allow_plaintext_in_transit=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
