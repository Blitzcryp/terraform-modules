data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt the log group with their key.
  create_kms = var.config.kms_key_arn == null

  log_group_name = "/${var.config.name_prefix}/audit"

  # Effective KMS ARN handed to the log-group atom: either the one we create or
  # the caller's BYO key.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # The log group ARN the flow-log role is scoped to. Computed (not the atom's
  # output) because the role's inline policy must be known at plan time without
  # depending on the log group resource's computed ARN.
  log_group_arn_scope = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"

  # ---------------------------------------------------------------------------
  # CRITICAL CORRECTNESS (apply-time): a CloudWatch log group encrypted with a
  # customer-managed CMK fails to create unless the key policy grants the
  # regional CloudWatch Logs service principal (logs.<region>.amazonaws.com)
  # permission to use the key. We therefore build a key policy that grants:
  #   (a) the account root full kms:* admin (same as the atom's default), and
  #   (b) logs.<region>.amazonaws.com the encrypt/decrypt/datakey actions,
  #       constrained to log groups in this account/region via the
  #       kms:EncryptionContext:aws:logs:arn condition (least privilege).
  # Only used when this component creates the key (BYO keys are the caller's
  # responsibility to authorise).
  # ---------------------------------------------------------------------------
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
    ]
  })

  # Trust policy for the VPC Flow Logs delivery role (PCI DSS Req 8: identify the
  # principal allowed to assume the role).
  flow_log_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowFlowLogsAssume"
        Effect    = "Allow"
        Principal = { Service = var.config.flow_log_role_trust_service }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # Least-privilege delivery policy: only the log stream/event actions VPC Flow
  # Logs needs, scoped to this component's log group (PCI DSS Req 7).
  flow_log_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DeliverFlowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
        ]
        Resource = [
          local.log_group_arn_scope,
          "${local.log_group_arn_scope}:*",
        ]
      },
    ]
  })
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Audit-logging CMK for ${var.config.name_prefix} (PCI DSS Req 10)"
    alias       = "${var.config.name_prefix}/audit"
    # Secure defaults inherited from the atom: rotation on, 30-day deletion
    # window, symmetric ENCRYPT_DECRYPT. We override only the policy so the
    # CloudWatch Logs service can use the key (see local.kms_policy).
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- Encrypted CloudWatch log group (the audit log sink) ----------------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.retention_in_days
    log_group_class   = var.config.log_group_class
    tags              = var.config.tags

    # Escape hatch passed straight through; encryption is always enforced here
    # because effective_kms_arn is never null.
    allow_no_retention = var.config.allow_no_retention
  }
}

# --- VPC Flow Logs delivery role (created only when requested) ----------------
module "flow_log_role" {
  source = "../../atoms/iam/iam-role"
  count  = var.config.create_flow_log_role ? 1 : 0

  config = {
    name_prefix        = "${var.config.name_prefix}-flowlogs-"
    description        = "VPC Flow Logs delivery role for ${var.config.name_prefix} audit logging"
    assume_role_policy = local.flow_log_assume_role_policy
    inline_policies = {
      "flow-logs-delivery" = local.flow_log_inline_policy
    }
    tags = var.config.tags
  }
}
