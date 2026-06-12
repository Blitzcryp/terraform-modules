data "aws_caller_identity" "current" {}

locals {
  # Query logging is only supported on PUBLIC hosted zones. Private zones skip
  # the CMK, the log group and the query-log wiring entirely.
  query_logging_enabled = !var.config.private_zone

  # Whether this component owns the CMK. A BYO key ARN skips the kms-key atom.
  create_kms = local.query_logging_enabled && var.config.kms_key_arn == null

  # Effective CMK ARN handed to the log-group atom: created or BYO.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  log_group_name = "/aws/route53/${var.config.name}"

  # Derived (not the atom's computed output) so the route53-zone atom can decide
  # its query-log count at plan time. The log group lives in us-east-1.
  query_log_group_arn = local.query_logging_enabled ? "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}:*" : null

  # ---------------------------------------------------------------------------
  # us-east-1 REQUIREMENT: AWS only delivers Route53 PUBLIC-zone query logs to a
  # CloudWatch Logs group in us-east-1. The caller must supply a provider aliased
  # to us-east-1 as `aws.use1`; the log group (and its CMK) are created there.
  # ---------------------------------------------------------------------------
  # CloudWatch Logs query-log delivery is region-scoped to us-east-1, so the CMK
  # policy authorises the us-east-1 Logs service principal to use the key. We
  # also scope the EncryptionContext condition to us-east-1 log groups in this
  # account (least privilege, PCI DSS Req 7). Only built when we own the key.
  logs_service_principal = "logs.us-east-1.amazonaws.com"

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
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
    ]
  })
}

# --- KMS CMK for query-log encryption (created only for public + no BYO key) --
# Created in us-east-1 alongside the log group so a same-region CMK encrypts it.
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  providers = {
    aws = aws.use1
  }

  config = {
    description = "Route53 query-log CMK for ${var.config.name} (PCI DSS Req 10)"
    policy      = local.kms_policy
    tags        = var.config.tags
  }
}

# --- Encrypted CloudWatch log group: the query-log destination ----------------
# MUST be in us-east-1 for public zones (AWS requirement) -> aws.use1 provider.
module "query_log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"
  count  = local.query_logging_enabled ? 1 : 0

  providers = {
    aws = aws.use1
  }

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- The hosted zone, with query logging wired to the us-east-1 log group ------
module "zone" {
  source = "../../atoms/route53/route53-zone"

  # The query-log destination ARN is derived (not the log group's output), so an
  # explicit dependency ensures the log group exists before logging is wired.
  depends_on = [module.query_log_group]

  config = {
    name         = var.config.name
    private_zone = var.config.private_zone
    vpc_ids      = var.config.vpc_ids

    # Public zones get a query-log destination; private zones cannot query-log,
    # so the destination is null and the atom skips logging without needing the
    # allow_query_logging_disabled escape hatch.
    query_log_destination_arn = local.query_log_group_arn

    tags = var.config.tags
  }
}
