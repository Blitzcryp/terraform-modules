data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/opensearch" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # This component owns the CMK unless the caller brings their own key ARN. When
  # BYO, we skip creating a kms-key atom and encrypt the domain + log group with
  # the supplied key (PCI DSS Req 3).
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # Predictable name for the audit/slow-log group (CMK-encrypted, PCI DSS Req 10).
  log_group_name = "/aws/opensearch/${var.config.name}"

  # HTTPS (443) is the only client port — the domain enforces HTTPS/TLS 1.2.
  # Ingress is built from the supplied client SGs and CIDRs only; no public
  # (0.0.0.0/0) ingress is ever generated (PCI DSS Req 1).
  sg_ingress_rules = [
    for sg in var.config.allowed_security_group_ids : {
      description                  = "OpenSearch HTTPS from client SG ${sg}"
      ip_protocol                  = "tcp"
      from_port                    = 443
      to_port                      = 443
      referenced_security_group_id = sg
    }
  ]
  cidr_ingress_rules = [
    for c in var.config.allowed_cidrs : {
      description = "OpenSearch HTTPS from ${c}"
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = c
    }
  ]
  ingress_rules = concat(local.sg_ingress_rules, local.cidr_ingress_rules)

  # CMK policy: account root admin + the regional OpenSearch and CloudWatch Logs
  # service principals so the domain can use the key at rest AND the CMK-encrypted
  # audit/slow-log group can be written. Only built when this component owns the
  # key (mirrors components/kafka).
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
        Sid       = "AllowOpenSearch"
        Effect    = "Allow"
        Principal = { Service = "es.amazonaws.com" }
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

# --- Domain security group (no public ingress; HTTPS/443 from supplied sources) -
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name        = "${var.config.name}-opensearch"
    vpc_id      = var.config.vpc_id
    description = "OpenSearch HTTPS access for ${var.config.name} (no public ingress)"

    ingress_rules = local.ingress_rules
    tags          = var.config.tags
  }
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "OpenSearch CMK for ${var.config.name} (PCI DSS Req 3)"
    alias       = "opensearch/${var.config.name}"
    policy      = local.kms_policy
    tags        = var.config.tags
  }
}

# --- KMS-encrypted audit/slow-log group (PCI DSS Req 10) ----------------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- OpenSearch domain (VPC-placed, encrypted at rest + in transit, FGAC) -----
module "domain" {
  source = "../../atoms/opensearch/opensearch-domain"

  config = {
    domain_name = var.config.name

    engine_version = var.config.engine_version
    instance_type  = var.config.instance_type
    instance_count = var.config.instance_count
    volume_size    = var.config.volume_size

    # Encryption at rest with the effective CMK (created or BYO); never null, so
    # the atom's at-rest precondition is satisfied without its escape hatch.
    kms_key_arn = local.effective_kms_arn

    # VPC placement (no public endpoint) gated by the component's security group.
    vpc_subnet_ids         = var.config.subnet_ids
    vpc_security_group_ids = [module.security_group.manifest.id]

    # Fine-grained access control master role (IAM); null still enables FGAC.
    master_user_arn = var.config.master_user_arn

    # Audit + error + search/index slow logs to the CMK-encrypted group (Req 10).
    cloudwatch_log_group_arn = module.log_group.manifest.arn

    tags = var.config.tags
  }
}
