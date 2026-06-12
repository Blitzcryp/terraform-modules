variable "config" {
  description = <<-EOT
    Configuration for the OpenSearch domain. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so the caller
    only has to supply the required `domain_name`: encryption at rest is on, node-to-node
    encryption is on, HTTPS is enforced with TLS 1.2, and fine-grained access control
    is on with an IAM master user. Insecure choices require flipping an explicit
    `allow_*` escape hatch (grep-able, auditable).
  EOT

  type = object({
    # --- Required: the caller must decide this ---
    domain_name = string # required — the OpenSearch domain name

    # --- Engine / sizing ---
    engine_version = optional(string, "OpenSearch_2.11")
    instance_type  = optional(string, "t3.small.search")
    instance_count = optional(number, 2)
    zone_awareness = optional(bool, true) # spread data nodes across AZs
    volume_size    = optional(number, 20) # EBS GiB per data node

    # --- Encryption at rest (PCI DSS Req 3) ---
    encrypt_at_rest = optional(bool, true) # PCI DSS Req 3
    # BYO CMK ARN; when null AWS uses the aws/es service key (still encrypted).
    kms_key_arn = optional(string)

    # --- Encryption in transit between nodes (PCI DSS Req 4) ---
    node_to_node_encryption = optional(bool, true)

    # --- Network exposure (PCI DSS Req 1) ---
    # When subnet_ids is non-empty the domain is placed inside the VPC (no public
    # endpoint). security_group_ids gate access at the ENI.
    vpc_subnet_ids         = optional(list(string), [])
    vpc_security_group_ids = optional(list(string), [])

    # --- Fine-grained access control (PCI DSS Req 7/8) ---
    # IAM master user by default (no password ever stored). Supplying master_user_arn
    # sets the master role; null still enables FGAC with internal DB disabled.
    master_user_arn = optional(string)

    # --- Audit / slow-log delivery (PCI DSS Req 10) ---
    # When set, audit + error + search/index slow logs are published to this group.
    cloudwatch_log_group_arn = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted    = optional(bool, false) # permit encrypt_at_rest.enabled=false
    allow_plaintext_node = optional(bool, false) # permit node_to_node_encryption.enabled=false
  })
  # no `default` — domain_name is required

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.config.domain_name))
    error_message = "config.domain_name must be 3-28 chars, start with a lowercase letter, and contain only lowercase letters, digits and hyphens."
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
}
