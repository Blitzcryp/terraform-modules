variable "config" {
  # SECURITY: this object carries the Redis AUTH token (config.auth_token), so the
  # whole variable is marked sensitive. PCI DSS Req 8: the token must NEVER be
  # hardcoded — supply it from a secrets manager (e.g. AWS Secrets Manager) at the
  # call site, never as a literal in source control.
  sensitive = true

  description = <<-EOT
    Configuration for the elasticache component (a secure-by-default, encrypted
    Redis caching tier). All inputs live on this single object. PCI-DSS-compliant
    defaults are baked into the optional() fields: encryption at rest (Req 3) and
    in transit (Req 4) are on, automatic failover and Multi-AZ are on, and the
    cache security group has NO public ingress — only the supplied app security
    groups / CIDRs may reach the Redis port (Req 1). Required fields (name, vpc_id,
    subnet_ids) have no default, so config cannot be omitted.

    PCI DSS Req 8: config.auth_token must come from a secrets manager — never a
    literal. The whole variable is marked sensitive because it carries the token.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # required — replication group id + subnet group + SG names
    vpc_id     = string       # required — VPC for the cache security group
    subnet_ids = list(string) # required — private subnets for the cache subnet group

    # --- Engine / sizing ---
    node_type          = optional(string, "cache.t4g.medium")
    num_cache_clusters = optional(number, 2)
    engine_version     = optional(string, "7.1")
    port               = optional(number, 6379)

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Access control (PCI DSS Req 8) ---
    # SECURITY: supply from a secrets manager, never a literal.
    auth_token = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # Redis-port ingress is allowed ONLY from these app security groups / CIDRs.
    # Empty lists => a cache security group with no ingress at all (most locked-down).
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    tags = optional(map(string), {})
  })
  # no `default` — name, vpc_id and subnet_ids are required

  validation {
    condition     = length(var.config.subnet_ids) >= 2
    error_message = "config.subnet_ids must list at least two subnets in distinct AZs for Multi-AZ cache resilience."
  }

  validation {
    condition     = var.config.num_cache_clusters > 1
    error_message = "config.num_cache_clusters must be > 1 (Multi-AZ + automatic failover require a replica)."
  }

  validation {
    condition     = var.config.port >= 1 && var.config.port <= 65535
    error_message = "config.port must be a valid TCP port (1-65535)."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}
