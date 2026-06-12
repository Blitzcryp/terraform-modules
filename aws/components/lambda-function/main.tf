data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/lambda-function" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  log_group_name = "/aws/lambda/${var.config.name}"

  # Whether this component owns the CMK. A BYO key skips the kms-key atom and is
  # used to encrypt both the env vars and the log group.
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # VPC attachment creates a dedicated security group and grants the role ENI
  # permissions.
  has_vpc = length(var.config.vpc_subnet_ids) > 0

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

  # Trust policy: only the Lambda service may assume the execution role
  # (PCI DSS Req 8: identify the principal allowed to assume the role).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowLambdaAssume"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # Least-privilege CloudWatch Logs delivery policy scoped to this function's log
  # group (PCI DSS Req 7).
  logs_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteFunctionLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          local.log_group_arn_scope,
          "${local.log_group_arn_scope}:*",
        ]
      },
    ]
  })

  # EC2 ENI management permissions Lambda needs for VPC access. These actions do
  # not support resource-level scoping, so Resource is "*" (this mirrors the AWS
  # managed AWSLambdaVPCAccessExecutionRole policy). Only attached when a VPC is
  # configured.
  vpc_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageVpcEnis"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Resource = "*"
      },
    ]
  })

  inline_policies = merge(
    { "cloudwatch-logs" = local.logs_inline_policy },
    local.has_vpc ? { "vpc-access" = local.vpc_inline_policy } : {}
  )

  # Default egress for the function SG: HTTPS-only outbound (reach AWS APIs,
  # Secrets Manager, etc.). Documented per PCI DSS Req 1.
  default_egress_rules = [{
    description = "Allow HTTPS outbound (AWS APIs, Secrets Manager)"
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_ipv4   = "0.0.0.0/0"
  }]

  egress_rules = length(var.config.egress_rules) > 0 ? var.config.egress_rules : local.default_egress_rules
}

# --- Customer-managed KMS key (created only when no BYO key is supplied) ------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Lambda CMK for ${var.config.name} (env vars + logs, PCI DSS Req 3)"
    alias       = "lambda/${var.config.name}"
    # Override only the policy so CloudWatch Logs can use the key; rotation /
    # deletion-window / spec secure defaults inherited from the atom.
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- Encrypted CloudWatch log group ( /aws/lambda/<name> ) --------------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn # never null -> always encrypted
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- Execution IAM role (trusts lambda.amazonaws.com; least-privilege) --------
module "exec_role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name_prefix        = "${var.config.name}-exec-"
    description        = "Lambda execution role for ${var.config.name}"
    assume_role_policy = local.assume_role_policy
    inline_policies    = local.inline_policies
    tags               = var.config.tags
  }
}

# --- Dedicated security group (created only when attaching to a VPC) ----------
module "security_group" {
  source = "../../atoms/vpc/security-group"
  count  = local.has_vpc ? 1 : 0

  config = {
    name        = "${var.config.name}-fn"
    vpc_id      = var.config.vpc_id
    description = "Lambda function SG for ${var.config.name}"

    # No ingress (Lambda ENIs are not addressed inbound). Egress per config or
    # HTTPS-only default.
    egress_rules = local.egress_rules

    tags = var.config.tags
  }
}

# --- The Lambda function ------------------------------------------------------
module "lambda_function" {
  source = "../../atoms/lambda/lambda-function"

  config = {
    function_name = var.config.name
    role          = module.exec_role.manifest.arn

    package_type = var.config.package_type
    runtime      = var.config.runtime
    handler      = var.config.handler
    filename     = var.config.filename
    s3_bucket    = var.config.s3_bucket
    s3_key       = var.config.s3_key
    image_uri    = var.config.image_uri
    layers       = var.config.layers

    memory_size                    = var.config.memory_size
    timeout                        = var.config.timeout
    reserved_concurrent_executions = var.config.reserved_concurrent_executions
    architectures                  = var.config.architectures

    # env vars always encrypted at rest with the effective CMK (never null).
    environment_variables = var.config.environment_variables
    kms_key_arn           = local.effective_kms_arn

    vpc_subnet_ids         = var.config.vpc_subnet_ids
    vpc_security_group_ids = local.has_vpc ? [module.security_group[0].manifest.id] : []

    dead_letter_target_arn = var.config.dead_letter_target_arn

    enable_xray = var.config.enable_xray

    tags = var.config.tags
  }
}
