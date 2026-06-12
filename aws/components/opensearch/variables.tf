variable "config" {
  description = <<-EOT
    Configuration for the opensearch component (a VPC-placed, secure-by-default
    OpenSearch domain with audit/slow-log delivery). All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields: the domain is encrypted at rest with a dedicated CMK, node-to-node
    encryption is on, HTTPS is enforced on TLS 1.2, and fine-grained access
    control is on with an IAM master user. The domain security group has NO
    public ingress — only the supplied client security groups / CIDRs may reach
    HTTPS (443). Audit + slow logs are published to a CMK-encrypted CloudWatch
    log group. Required fields (name, vpc_id, subnet_ids) have no default, so
    config cannot be omitted.

    Note: the CloudWatch Logs resource policy that lets es.amazonaws.com write to
    the log group is an account-level concern (set once per account/region) and
    is intentionally not created here — this component composes atoms only.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string       # required — the OpenSearch domain name
    vpc_id     = string       # required — VPC for the domain security group
    subnet_ids = list(string) # required — private subnets for VPC placement

    # --- Engine / sizing ---
    engine_version = optional(string, "OpenSearch_2.11")
    instance_type  = optional(string, "t3.small.search")
    instance_count = optional(number, 2)
    volume_size    = optional(number, 20) # EBS GiB per data node

    # --- Encryption at rest (PCI DSS Req 3) ---
    # BYO CMK ARN; when null the component creates a dedicated KMS key.
    kms_key_arn = optional(string)

    # --- Network exposure (PCI DSS Req 1) ---
    # HTTPS (443) ingress is allowed ONLY from these client security groups /
    # CIDRs. Empty lists => a domain security group with no ingress at all.
    allowed_security_group_ids = optional(list(string), [])
    allowed_cidrs              = optional(list(string), [])

    # --- Fine-grained access control (PCI DSS Req 7/8) ---
    # IAM master role ARN; null still enables FGAC with the internal user
    # database disabled (no stored password).
    master_user_arn = optional(string)

    # --- Audit / slow-log retention (PCI DSS Req 10) ---
    log_retention_days = optional(number, 365) # >= 1 year of audit logs

    tags = optional(map(string), {})
  })
  # no `default` — name, vpc_id and subnet_ids are required

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.config.name))
    error_message = "config.name must be 3-28 chars, start with a lowercase letter, and contain only lowercase letters, digits and hyphens (OpenSearch domain naming)."
  }

  validation {
    condition     = length(var.config.subnet_ids) >= 1
    error_message = "config.subnet_ids must list at least one private subnet for VPC placement."
  }

  validation {
    condition     = var.config.instance_count >= 1
    error_message = "config.instance_count must be at least 1."
  }

  validation {
    condition     = var.config.volume_size >= 10
    error_message = "config.volume_size must be at least 10 GiB."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = alltrue([for c in var.config.allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Each config.allowed_cidrs entry must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }
}
