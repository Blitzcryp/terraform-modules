data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/ecs-cluster" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt the log group + ECS Exec with it.
  create_kms = var.config.kms_key_arn == null

  # CloudWatch log group for ECS Exec / container audit logs.
  log_group_name = "/ecs/${var.config.name}/exec"

  # Effective KMS ARN handed to the log-group atom and the cluster atom: either
  # the one we create or the caller's BYO key.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  logs_service_principal = "logs.${data.aws_region.current.name}.amazonaws.com"

  # ---------------------------------------------------------------------------
  # CRITICAL CORRECTNESS (apply-time): a CloudWatch log group encrypted with a
  # customer-managed CMK fails to create unless the key policy grants the
  # regional CloudWatch Logs service principal (logs.<region>.amazonaws.com)
  # permission to use the key. We build a key policy granting:
  #   (a) the account root full kms:* admin (same as the atom's default), and
  #   (b) logs.<region>.amazonaws.com the encrypt/decrypt/datakey actions,
  #       constrained to log groups in this account/region via the
  #       kms:EncryptionContext:aws:logs:arn condition (least privilege).
  # Only used when this component creates the key (BYO keys are the caller's
  # responsibility to authorise).
  # ---------------------------------------------------------------------------
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
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "ECS cluster CMK for ${var.config.name} (ECS Exec + log encryption)"
    alias       = "ecs/${var.config.name}"
    # Secure defaults inherited from the atom: rotation on, 30-day deletion
    # window, symmetric ENCRYPT_DECRYPT. Override only the policy so the
    # CloudWatch Logs service can use the key (see local.kms_policy).
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- Encrypted CloudWatch log group (ECS Exec / container audit logs) ---------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
    # encryption is always enforced here because effective_kms_arn is never null.
  }
}

# --- ECS cluster --------------------------------------------------------------
module "ecs_cluster" {
  source = "../../atoms/ecs/ecs-cluster"

  config = {
    name = var.config.name

    # Wire encrypted ECS Exec audit logging: both the CMK and the log group name
    # must be present for the atom to enable OVERRIDE logging with encryption.
    kms_key_arn                    = local.effective_kms_arn
    execute_command_log_group_name = module.log_group.manifest.name

    capacity_providers = var.config.capacity_providers

    tags = var.config.tags
    # Container Insights stays on (secure default inherited from the atom).
  }
}
