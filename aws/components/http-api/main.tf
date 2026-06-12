data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  module_tags = {
    Module = "components/http-api" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt the access-log group with their key.
  create_kms = var.config.kms_key_arn == null

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  log_group_name = "/aws/apigateway/${var.config.name}"

  # Effective KMS ARN handed to the log-group atom: either the one we create or
  # the caller's BYO key.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # CORS is configured on the API only when origins are supplied.
  has_cors = length(var.config.cors_allow_origins) > 0

  # ---------------------------------------------------------------------------
  # APPLY-TIME CORRECTNESS — derived ARNs.
  # The access-log group ARN is known at plan time (no dependency on a computed
  # resource output), so the KMS key policy can be built before the log group
  # exists, avoiding plan-time-unknown cycles. The stage's access-log destination
  # must be the bare group ARN (API Gateway appends the stream itself).
  # ---------------------------------------------------------------------------
  log_group_arn = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${local.log_group_name}"
  logs_service  = "logs.${local.region}.amazonaws.com"

  # ---------------------------------------------------------------------------
  # KMS key policy (only used when this component creates the CMK; BYO keys are
  # the caller's responsibility to authorise). Grants:
  #   (a) account root full kms:* admin (same as the atom default), and
  #   (b) logs.<region>.amazonaws.com the encrypt/decrypt/datakey actions so the
  #       CMK-encrypted CloudWatch access-log group can be created, constrained
  #       by the kms:EncryptionContext:aws:logs:arn condition (least privilege).
  # ---------------------------------------------------------------------------
  kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = local.logs_service }
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
            "kms:EncryptionContext:aws:logs:arn" = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:*"
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
    description = "HTTP API access-log CMK for ${var.config.name} (PCI DSS Req 3/10)"
    alias       = "${var.config.name}/http-api-logs"
    # Secure defaults inherited from the atom (rotation on, 30-day window,
    # symmetric ENCRYPT_DECRYPT). We override only the policy so CloudWatch Logs
    # can use the key (see local.kms_policy).
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- CloudWatch log group for access logs (KMS-encrypted, PCI DSS Req 10) -----
module "access_log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- The HTTP API ------------------------------------------------------------
module "api" {
  source = "../../atoms/apigateway/apigatewayv2-api"

  config = {
    name          = var.config.name
    protocol_type = "HTTP"

    cors_configuration = local.has_cors ? {
      allow_origins = var.config.cors_allow_origins
    } : null

    tags = var.config.tags
  }
}

# --- AWS_PROXY integration to the Lambda -------------------------------------
module "integration" {
  source = "../../atoms/apigateway/apigatewayv2-integration"

  config = {
    api_id           = module.api.manifest.id
    integration_type = "AWS_PROXY"
    integration_uri  = var.config.lambda_invoke_arn
    # Secure defaults inherited: integration_method POST, payload format 2.0,
    # INTERNET connection.
    tags = var.config.tags
  }
}

# --- One route per entry in config.routes, all targeting the integration ------
module "route" {
  source   = "../../atoms/apigateway/apigatewayv2-route"
  for_each = toset(var.config.routes)

  config = {
    api_id    = module.api.manifest.id
    route_key = each.value
    target    = "integrations/${module.integration.manifest.integration_id}"
    # authorization_type defaults to NONE in the atom; callers fronting protected
    # resources should attach an authorizer at the route level.
    tags = var.config.tags
  }
}

# --- The stage, with access logging + throttling on ---------------------------
module "stage" {
  source = "../../atoms/apigateway/apigatewayv2-stage"

  config = {
    api_id = module.api.manifest.id
    # $default stage with auto_deploy inherited from the atom defaults.
    access_log_destination_arn = module.access_log_group.manifest.arn
    throttling_burst_limit     = var.config.throttling_burst_limit
    throttling_rate_limit      = var.config.throttling_rate_limit
    tags                       = var.config.tags
  }
}
