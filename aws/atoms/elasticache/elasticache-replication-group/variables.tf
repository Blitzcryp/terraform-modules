variable "config" {
  # SECURITY: this object carries the Redis AUTH token (config.auth_token), so the
  # whole variable is marked sensitive. PCI DSS Req 8: the token must NEVER be
  # hardcoded — supply it from a secrets manager (e.g. AWS Secrets Manager) at the
  # call site, never as a literal in source control.
  sensitive = true

  description = <<-EOT
    Configuration for the ElastiCache (Redis) replication group. All inputs live on
    this single object. PCI-DSS-compliant defaults are baked into the optional()
    fields: encryption at rest is on (PCI Req 3), encryption in transit is on
    (PCI Req 4), automatic failover and Multi-AZ are on, and snapshots are retained.
    Insecure choices require flipping an explicit `allow_*` escape hatch.

    PCI DSS Req 8: config.auth_token must come from a secrets manager — never a
    literal. The whole variable is marked sensitive because it carries the token.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    replication_group_id = string       # required — identifier (stored lowercase)
    subnet_group_name    = string       # required — cache subnet group name
    security_group_ids   = list(string) # required — VPC security group IDs

    description = optional(string, "Managed by terraform (atoms/elasticache/elasticache-replication-group)")

    # --- Engine / sizing ---
    engine               = optional(string, "redis")
    engine_version       = optional(string, "7.1")
    node_type            = optional(string, "cache.t4g.medium")
    port                 = optional(number, 6379)
    parameter_group_name = optional(string) # null = engine-specific default group

    # --- Topology / resilience ---
    automatic_failover_enabled = optional(bool, true)
    multi_az_enabled           = optional(bool, true)
    num_cache_clusters         = optional(number, 2) # >1 so automatic failover is possible
    snapshot_retention_limit   = optional(number, 7)

    # --- Encryption at rest (PCI DSS Req 3) ---
    at_rest_encryption_enabled = optional(bool, true)
    kms_key_arn                = optional(string) # CMK; null = AWS-managed key

    # --- Encryption in transit (PCI DSS Req 4) ---
    transit_encryption_enabled = optional(bool, true)

    # --- Access control (PCI DSS Req 8) ---
    # SECURITY: supply from a secrets manager, never a literal. Recommended when
    # transit encryption is on. Requires transit_encryption_enabled = true.
    auth_token = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted_at_rest  = optional(bool, false) # permit at_rest_encryption_enabled = false
    allow_plaintext_in_transit = optional(bool, false) # permit transit_encryption_enabled = false
  })
  # no `default` — replication_group_id, subnet_group_name, security_group_ids are required

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,39}$", var.config.replication_group_id))
    error_message = "config.replication_group_id must be lowercase, start with a letter, and be 1-40 chars of [a-z0-9-]."
  }

  validation {
    condition     = var.config.port >= 1 && var.config.port <= 65535
    error_message = "config.port must be a valid TCP port (1-65535)."
  }

  validation {
    condition     = length(var.config.security_group_ids) >= 1
    error_message = "config.security_group_ids must list at least one security group."
  }

  # auth_token may only be set when transit encryption is enabled (provider constraint).
  validation {
    condition     = var.config.auth_token == null || var.config.transit_encryption_enabled
    error_message = "config.auth_token can be set only when config.transit_encryption_enabled = true (PCI DSS Req 8 + provider constraint)."
  }

  # Multi-AZ requires automatic failover (provider constraint).
  validation {
    condition     = !var.config.multi_az_enabled || var.config.automatic_failover_enabled
    error_message = "config.multi_az_enabled requires config.automatic_failover_enabled = true."
  }

  # Automatic failover requires more than one cache cluster (provider constraint).
  validation {
    condition     = !var.config.automatic_failover_enabled || var.config.num_cache_clusters > 1
    error_message = "config.automatic_failover_enabled requires config.num_cache_clusters > 1."
  }
}
