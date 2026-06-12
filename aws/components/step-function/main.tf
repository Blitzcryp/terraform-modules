data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/step-function" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Step Functions execution logging convention: /aws/vendedlogs/states/<name>.
  log_group_name = "/aws/vendedlogs/states/${var.config.name}"

  # Whether this component owns the CMK. A BYO key skips the kms-key atom and is
  # used to encrypt the execution log group.
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  logs_service_principal = "logs.${data.aws_region.current.name}.amazonaws.com"

  # The log group ARN scope the execution role's inline policy targets. Computed
  # (not the atom's output) so the policy is fully known at plan time.
  log_group_arn_scope = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"

  # ---------------------------------------------------------------------------
  # APPLY-TIME CORRECTNESS: a CloudWatch log group encrypted with a customer-
  # managed CMK fails to create unless the key policy grants the regional
  # CloudWatch Logs service principal (logs.<region>.amazonaws.com) use of the
  # key, constrained to log groups in this account/region. Only built when this
  # component creates the key (BYO keys are the caller's responsibility).
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

  # Trust policy: only the Step Functions service may assume the execution role
  # (PCI DSS Req 8: identify the principal allowed to assume the role).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowStatesAssume"
        Effect    = "Allow"
        Principal = { Service = "states.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # Least-privilege policy for the controls this component owns: CloudWatch Logs
  # delivery (vended logs) + X-Ray tracing. The Logs delivery and X-Ray actions
  # do not support resource-level scoping, so Resource is "*" (this mirrors the
  # AWS-managed AWSStepFunctions* policies). PCI DSS Req 7 / Req 10.
  observability_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DeliverExecutionLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
        ]
        Resource = "*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
        ]
        Resource = "*"
      },
    ]
  })

  # The execution role's inline policies: always the observability policy, plus
  # the caller-supplied workflow policy (downstream service invocations) when set.
  inline_policies = merge(
    { "observability" = local.observability_inline_policy },
    var.config.additional_policy_json != null ? { "workflow" = var.config.additional_policy_json } : {}
  )
}

# --- Customer-managed KMS key (created only when no BYO key is supplied) ------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Step Functions CMK for ${var.config.name} (execution logs, PCI DSS Req 3)"
    alias       = "states/${var.config.name}"
    # Override only the policy so CloudWatch Logs can use the key; rotation /
    # deletion-window / spec secure defaults inherited from the atom.
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- Encrypted CloudWatch log group ( /aws/vendedlogs/states/<name> ) ---------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn # never null -> always encrypted
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- Execution IAM role (trusts states.amazonaws.com; least-privilege) --------
module "exec_role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name_prefix        = "${var.config.name}-sfn-"
    description        = "Step Functions execution role for ${var.config.name}"
    assume_role_policy = local.assume_role_policy
    inline_policies    = local.inline_policies
    tags               = var.config.tags
  }
}

# --- The Step Functions state machine -----------------------------------------
module "state_machine" {
  source = "../../atoms/sfn/sfn-state-machine"

  config = {
    name       = var.config.name
    definition = var.config.definition
    role_arn   = module.exec_role.manifest.arn
    type       = var.config.type

    # Logging is always enabled (encrypted, owned log group destination), so the
    # atom's allow_no_logging escape hatch is never needed here.
    log_destination_arn    = module.log_group.manifest.arn
    log_level              = var.config.log_level
    include_execution_data = var.config.include_execution_data
    enable_tracing         = true # X-Ray on (PCI DSS Req 10)

    tags = var.config.tags
  }
}
