locals {
  module_tags = {
    Module = "atoms/msk/msk-cluster" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  logging_enabled = var.config.cloudwatch_log_group_name != null
}

resource "aws_msk_cluster" "this" {
  # checkov:skip=CKV_AWS_81: Encryption in transit (TLS client_broker + in_cluster)
  #   and at rest are enforced by the secure optional() defaults and the lifecycle
  #   preconditions below; checkov cannot resolve object-type optional() defaults
  #   through the module call (false positive). Verified by tests/defaults.tftest.hcl.
  #   Exceptions tracked by security@emag.ro.
  # checkov:skip=CKV_AWS_80: Broker logging to CloudWatch is enabled by the
  #   logging_info block whenever config.cloudwatch_log_group_name is set and is
  #   guarded by a lifecycle precondition; checkov cannot resolve the value through
  #   the module call (false positive). Verified by tests/defaults.tftest.hcl.
  cluster_name           = var.config.cluster_name
  kafka_version          = var.config.kafka_version
  number_of_broker_nodes = var.config.number_of_broker_nodes
  enhanced_monitoring    = var.config.enhanced_monitoring

  broker_node_group_info {
    instance_type   = var.config.broker_instance_type
    client_subnets  = var.config.client_subnets
    security_groups = var.config.security_groups

    storage_info {
      ebs_storage_info {
        volume_size = var.config.ebs_volume_size
      }
    }
  }

  # Encryption at rest (PCI DSS Req 3) + in transit (PCI DSS Req 4).
  # When kms_key_arn is null, MSK still encrypts at rest with an AWS-managed key.
  encryption_info {
    encryption_at_rest_kms_key_arn = var.config.kms_key_arn

    encryption_in_transit {
      client_broker = var.config.encryption_in_transit_client_broker
      in_cluster    = var.config.in_cluster_encryption
    }
  }

  # Client authentication (PCI DSS Req 7/8). Default: SASL/IAM on.
  client_authentication {
    sasl {
      iam   = var.config.sasl_iam_enabled
      scram = var.config.sasl_scram_enabled
    }
    tls {
      certificate_authority_arns = []
    }
  }

  # Broker logging to CloudWatch (PCI DSS Req 10). Enabled when a log group is given.
  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = local.logging_enabled
        log_group = var.config.cloudwatch_log_group_name
      }
    }
  }

  dynamic "open_monitoring" {
    for_each = var.config.open_monitoring ? [1] : []
    content {
      prometheus {
        jmx_exporter {
          enabled_in_broker = true
        }
        node_exporter {
          enabled_in_broker = true
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    # PCI DSS Req 3: prefer a customer-managed CMK. Relying on the AWS-managed
    # key must be intentional.
    precondition {
      condition     = var.config.kms_key_arn != null || var.config.allow_unencrypted_at_rest
      error_message = "No customer-managed KMS key provided. Set config.kms_key_arn, or file a PCI exception (security@emag.ro) and set config.allow_unencrypted_at_rest=true to accept the AWS-managed key."
    }

    # PCI DSS Req 4: client-broker traffic must be TLS unless explicitly relaxed.
    precondition {
      condition     = var.config.encryption_in_transit_client_broker == "TLS" || var.config.allow_plaintext_in_transit
      error_message = "client_broker is not TLS. Plaintext in transit requires a PCI exception (security@emag.ro); set config.allow_plaintext_in_transit=true."
    }

    # PCI DSS Req 4: in-cluster encryption must stay on unless plaintext explicitly allowed.
    precondition {
      condition     = var.config.in_cluster_encryption || var.config.allow_plaintext_in_transit
      error_message = "in-cluster encryption disabled. Requires a PCI exception (security@emag.ro); set config.allow_plaintext_in_transit=true."
    }

    # PCI DSS Req 10: broker logs to CloudWatch unless explicitly disabled.
    precondition {
      condition     = local.logging_enabled || var.config.allow_logging_disabled
      error_message = "Broker logging disabled. Provide config.cloudwatch_log_group_name, or file a PCI exception (security@emag.ro) and set config.allow_logging_disabled=true."
    }
  }
}
