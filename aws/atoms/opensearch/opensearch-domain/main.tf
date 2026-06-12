locals {
  module_tags = {
    Module = "atoms/opensearch/opensearch-domain" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Place the domain inside a VPC only when subnets are supplied; otherwise it is
  # a public-endpoint domain (still HTTPS + FGAC enforced).
  in_vpc = length(var.config.vpc_subnet_ids) > 0

  # Audit + slow logs are delivered only when a log group ARN is supplied.
  log_delivery = var.config.cloudwatch_log_group_arn != null
  log_types    = ["AUDIT_LOGS", "ES_APPLICATION_LOGS", "SEARCH_SLOW_LOGS", "INDEX_SLOW_LOGS"]
}

resource "aws_opensearch_domain" "this" {
  # checkov:skip=CKV_AWS_5: encrypt_at_rest.enabled defaults true via config (optional(bool, true));
  # checkov:skip=CKV_AWS_317: audit logging is wired when config.cloudwatch_log_group_arn is supplied;
  # checkov cannot statically resolve these values through the config object, but the secure defaults
  # are enforced by the secure_defaults test and disabling encryption requires the auditable
  # config.allow_unencrypted escape hatch (PCI DSS Req 3/10).
  # checkov:skip=CKV_AWS_318: three dedicated master nodes are an HA recommendation, not a PCI control;
  # the secure default is a 2-node zone-aware cluster. Callers needing HA masters size via config.
  domain_name    = var.config.domain_name
  engine_version = var.config.engine_version

  cluster_config {
    instance_type          = var.config.instance_type
    instance_count         = var.config.instance_count
    zone_awareness_enabled = var.config.zone_awareness

    dynamic "zone_awareness_config" {
      for_each = var.config.zone_awareness ? [1] : []
      content {
        availability_zone_count = var.config.instance_count >= 3 ? 3 : 2
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.config.volume_size
    volume_type = "gp3"
  }

  # Encryption at rest (PCI DSS Req 3). kms_key_id null => AWS-managed aws/es key.
  encrypt_at_rest {
    enabled    = var.config.encrypt_at_rest
    kms_key_id = var.config.kms_key_arn
  }

  # Node-to-node encryption in transit (PCI DSS Req 4).
  node_to_node_encryption {
    enabled = var.config.node_to_node_encryption
  }

  # Enforce HTTPS with a modern TLS policy (PCI DSS Req 4).
  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Fine-grained access control (PCI DSS Req 7/8): IAM master user, no internal
  # user database (so no master password is ever stored). FGAC requires
  # encrypt_at_rest, node_to_node_encryption and enforce_https — all on above.
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = false

    dynamic "master_user_options" {
      for_each = var.config.master_user_arn != null ? [1] : []
      content {
        master_user_arn = var.config.master_user_arn
      }
    }
  }

  # Optional VPC placement (no public endpoint when subnets are supplied).
  dynamic "vpc_options" {
    for_each = local.in_vpc ? [1] : []
    content {
      subnet_ids         = var.config.vpc_subnet_ids
      security_group_ids = var.config.vpc_security_group_ids
    }
  }

  # Audit + error + slow-log publishing to CloudWatch (PCI DSS Req 10).
  dynamic "log_publishing_options" {
    for_each = local.log_delivery ? toset(local.log_types) : toset([])
    content {
      cloudwatch_log_group_arn = var.config.cloudwatch_log_group_arn
      log_type                 = log_publishing_options.value
      enabled                  = true
    }
  }

  tags = local.tags

  # Encryption controls must be intentional to weaken (PCI DSS Req 3/4).
  lifecycle {
    precondition {
      condition     = var.config.encrypt_at_rest || var.config.allow_unencrypted
      error_message = "Encryption at rest disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    precondition {
      condition     = var.config.node_to_node_encryption || var.config.allow_plaintext_node
      error_message = "Node-to-node encryption disabled without config.allow_plaintext_node=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
