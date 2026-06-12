data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/kafka" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt the cluster/log group with their key.
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # Predictable name for the broker log group (CMK-encrypted, PCI DSS Req 10).
  log_group_name = "/aws/msk/${var.config.name}"

  # Kafka client->broker ports. Brokers expose TLS on 9094 and SASL/IAM on 9098;
  # plaintext 9092 is deliberately NOT opened (PCI DSS Req 4 in transit).
  kafka_tls_ports = [
    { from = 9094, to = 9094, desc = "Kafka TLS" },
    { from = 9098, to = 9098, desc = "Kafka SASL/IAM" },
  ]

  # Build ingress rules from the supplied client SGs and CIDRs only — no public
  # (0.0.0.0/0) ingress is ever generated (PCI DSS Req 1). One rule per
  # source x port, each with a required documented description.
  sg_ingress_rules = concat(
    flatten([
      for sg in var.config.allowed_security_group_ids : [
        for p in local.kafka_tls_ports : {
          description                  = "${p.desc} from client SG ${sg}"
          ip_protocol                  = "tcp"
          from_port                    = p.from
          to_port                      = p.to
          referenced_security_group_id = sg
        }
      ]
    ]),
    flatten([
      for cidr in var.config.allowed_cidrs : [
        for p in local.kafka_tls_ports : {
          description = "${p.desc} from ${cidr}"
          ip_protocol = "tcp"
          from_port   = p.from
          to_port     = p.to
          cidr_ipv4   = cidr
        }
      ]
    ]),
  )

  # CMK policy: account root admin + the regional MSK / CloudWatch Logs service
  # principals so the cluster can use the key at rest AND the CMK-encrypted
  # broker log group can be created (apply-time correctness; mirrors
  # audit-logging). Only built when this component owns the key.
  logs_service_principal = "logs.${data.aws_region.current.name}.amazonaws.com"

  kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = local.logs_service_principal }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
      {
        Sid       = "AllowMSK"
        Effect    = "Allow"
        Principal = { Service = "kafka.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
    ]
  })
}

# --- Broker security group (no public ingress; Kafka TLS ports only) ----------
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name        = "${var.config.name}-msk"
    vpc_id      = var.config.vpc_id
    description = "MSK broker SG for ${var.config.name} (Kafka TLS clients only)"

    ingress_rules = local.sg_ingress_rules
    tags          = var.config.tags
  }
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Kafka (MSK) CMK for ${var.config.name} (PCI DSS Req 3)"
    alias       = "msk/${var.config.name}"
    policy      = local.kms_policy
    tags        = var.config.tags
  }
}

# --- KMS-encrypted broker log group (PCI DSS Req 10) --------------------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- MSK cluster (TLS in transit, CMK at rest, SASL/IAM, broker logging) ------
module "msk_cluster" {
  source = "../../atoms/msk/msk-cluster"

  config = {
    cluster_name           = var.config.name
    kafka_version          = var.config.kafka_version
    number_of_broker_nodes = var.config.number_of_broker_nodes
    broker_instance_type   = var.config.broker_instance_type
    client_subnets         = var.config.client_subnets
    security_groups        = [module.security_group.manifest.id]

    # Encryption at rest with the effective CMK (created or BYO); never null, so
    # the atom's at-rest precondition is satisfied without its escape hatch.
    kms_key_arn = local.effective_kms_arn

    # SASL/IAM auth + TLS in transit are the atom's secure defaults.

    # Broker logs to the CMK-encrypted log group (PCI DSS Req 10).
    cloudwatch_log_group_name = module.log_group.manifest.name

    tags = var.config.tags
  }
}
