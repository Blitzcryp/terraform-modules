data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt the bucket, log group, firehose SSE
  # and S3 delivery with their key.
  create_kms = var.config.kms_key_arn == null

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  bucket_name     = "${var.config.name}-firehose-delivery-${local.account_id}"
  log_group_name  = "/aws/kinesisfirehose/${var.config.name}"
  log_stream_name = "S3Delivery"
  stream_name     = var.config.name

  # Effective KMS ARN handed to every atom: either the one we create or the
  # caller's BYO key. Never null here.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # ---------------------------------------------------------------------------
  # APPLY-TIME CORRECTNESS — derived ARNs.
  # All known at plan time (no dependency on a resource's computed output), so
  # the S3/KMS/role policies below can be built before the resources exist and
  # we avoid plan-time-unknown cycles.
  # ---------------------------------------------------------------------------
  bucket_arn    = "arn:${local.partition}:s3:::${local.bucket_name}"
  log_group_arn = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${local.log_group_name}"

  firehose_service = "firehose.amazonaws.com"
  logs_service     = "logs.${local.region}.amazonaws.com"

  # Trust policy for the Firehose delivery role.
  firehose_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowFirehoseAssume"
        Effect    = "Allow"
        Principal = { Service = local.firehose_service }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # ---------------------------------------------------------------------------
  # Least-privilege delivery policy (PCI DSS Req 7). Firehose needs to:
  #   (a) write objects to the delivery bucket and read bucket metadata, and
  #   (b) use the CMK to encrypt those objects (GenerateDataKey/Decrypt), and
  #   (c) write its own delivery-error log stream to the error log group.
  # ---------------------------------------------------------------------------
  firehose_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Delivery"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
        ]
        Resource = [
          local.bucket_arn,
          "${local.bucket_arn}/*",
        ]
      },
      {
        Sid    = "KmsForDelivery"
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt",
        ]
        Resource = [local.effective_kms_arn]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${local.region}.amazonaws.com"
          }
          StringLike = {
            "kms:EncryptionContext:aws:s3:arn" = "${local.bucket_arn}/*"
          }
        }
      },
      {
        Sid    = "CloudWatchErrorLogging"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
        ]
        Resource = ["${local.log_group_arn}:*"]
      },
    ]
  })

  # ---------------------------------------------------------------------------
  # KMS key policy (only used when this component creates the CMK; BYO keys are
  # the caller's responsibility to authorise). Grants:
  #   (a) account root full kms:* admin (same as the atom default), and
  #   (b) firehose.amazonaws.com GenerateDataKey/Decrypt (SSE of the buffer and
  #       envelope encryption for S3 delivery), and
  #   (c) the regional CloudWatch Logs service the encrypt/decrypt/datakey
  #       actions so the CMK-encrypted error log group can be written, scoped by
  #       the kms:EncryptionContext:aws:logs:arn condition (least privilege).
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
        Sid       = "AllowFirehoseUse"
        Effect    = "Allow"
        Principal = { Service = local.firehose_service }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt",
        ]
        Resource = "*"
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
    description = "Firehose-to-S3 CMK for ${var.config.name} (PCI DSS Req 3/10)"
    alias       = "${var.config.name}/firehose-to-s3"
    # Secure defaults inherited from the atom (rotation on, 30-day window,
    # symmetric ENCRYPT_DECRYPT). We override only the policy so Firehose and
    # CloudWatch Logs can use the key (see local.kms_policy).
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- S3 delivery bucket (the record landing zone, KMS-encrypted) --------------
module "delivery_bucket" {
  source = "../../atoms/s3/s3-bucket"

  config = {
    bucket      = local.bucket_name
    kms_key_arn = local.effective_kms_arn
    tags        = var.config.tags
    # Secure defaults inherited: encryption on, versioning on, public access
    # blocked, BucketOwnerEnforced ownership, TLS-only bucket policy.
  }
}

# --- CloudWatch error log group (delivery failures, KMS-encrypted) ------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- Firehose delivery role ---------------------------------------------------
module "firehose_role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name_prefix        = "${var.config.name}-firehose-"
    description        = "Firehose-to-S3 delivery role for ${var.config.name}"
    assume_role_policy = local.firehose_assume_role_policy
    inline_policies = {
      "firehose-s3-delivery" = local.firehose_inline_policy
    }
    tags = var.config.tags
  }
}

# --- The Firehose delivery stream, wired to all of the above ------------------
module "firehose" {
  source = "../../atoms/kinesis/kinesis-firehose-delivery-stream"

  config = {
    name        = local.stream_name
    bucket_arn  = module.delivery_bucket.manifest.arn
    role_arn    = module.firehose_role.manifest.arn
    kms_key_arn = local.effective_kms_arn

    buffering_size     = var.config.buffering_size
    buffering_interval = var.config.buffering_interval
    prefix             = var.config.prefix

    cloudwatch_log_group_name  = module.log_group.manifest.name
    cloudwatch_log_stream_name = local.log_stream_name

    tags = var.config.tags
    # Secure defaults inherited: SSE with CUSTOMER_MANAGED_CMK, KMS-encrypted S3
    # delivery, CloudWatch error logging enabled.
  }

  # The stream's create call requires the role's policy and the bucket to exist.
  depends_on = [
    module.delivery_bucket,
    module.firehose_role,
    module.log_group,
  ]
}
