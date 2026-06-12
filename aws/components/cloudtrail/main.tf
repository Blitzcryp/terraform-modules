data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt the trail + log group with their key.
  create_kms = var.config.kms_key_arn == null

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  bucket_name    = "${var.config.name}-cloudtrail-logs-${local.account_id}"
  log_group_name = "/aws/cloudtrail/${var.config.name}"
  trail_name     = var.config.name

  # Effective KMS ARN handed to the trail and log-group atoms: either the one we
  # create or the caller's BYO key.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # ---------------------------------------------------------------------------
  # APPLY-TIME CORRECTNESS — derived ARNs.
  # These are all known at plan time (no dependency on a resource's computed
  # output), so the S3/KMS/role policies below can be built before the resources
  # exist and we avoid plan-time-unknown cycles.
  # ---------------------------------------------------------------------------
  trail_arn          = "arn:${local.partition}:cloudtrail:${local.region}:${local.account_id}:trail/${local.trail_name}"
  bucket_arn         = "arn:${local.partition}:s3:::${local.bucket_name}"
  log_group_arn      = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${local.log_group_name}"
  logs_service       = "logs.${local.region}.amazonaws.com"
  cloudtrail_service = "cloudtrail.amazonaws.com"

  # CloudTrail's cloud_watch_logs_group_arn must be the log-stream-scoped form
  # (ending with :*), distinct from the bare group ARN used in the IAM policy.
  cloud_watch_logs_group_arn_for_trail = "${local.log_group_arn}:*"

  # ---------------------------------------------------------------------------
  # KMS key policy (only used when this component creates the CMK; BYO keys are
  # the caller's responsibility to authorise). Grants:
  #   (a) account root full kms:* admin (same as the atom default), and
  #   (b) cloudtrail.amazonaws.com GenerateDataKey* (to encrypt log files) and
  #       Decrypt (to read its own digest/log files), scoped by aws:SourceArn to
  #       this trail, and
  #   (c) logs.<region>.amazonaws.com the encrypt/decrypt/datakey actions so the
  #       CMK-encrypted CloudWatch log group can be created, constrained by the
  #       kms:EncryptionContext:aws:logs:arn condition (least privilege).
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
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = local.cloudtrail_service }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:${local.partition}:cloudtrail:*:${local.account_id}:trail/*"
          }
        }
      },
      {
        Sid       = "AllowCloudTrailDescribeDecrypt"
        Effect    = "Allow"
        Principal = { Service = local.cloudtrail_service }
        Action = [
          "kms:DescribeKey",
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

  # ---------------------------------------------------------------------------
  # S3 bucket policy statements injected into the s3-bucket atom (which already
  # adds DenyInsecureTransport). CloudTrail log delivery requires exactly:
  #   - AWSCloudTrailAclCheck : s3:GetBucketAcl on the bucket, and
  #   - AWSCloudTrailWrite    : s3:PutObject under AWSLogs/<account>/* with the
  #                             bucket-owner-full-control ACL.
  # Both are scoped by aws:SourceArn to this trail so only our trail may write.
  # ---------------------------------------------------------------------------
  bucket_policy_statements = [
    {
      Sid       = "AWSCloudTrailAclCheck"
      Effect    = "Allow"
      Principal = { Service = local.cloudtrail_service }
      Action    = "s3:GetBucketAcl"
      Resource  = local.bucket_arn
      Condition = {
        StringEquals = { "aws:SourceArn" = local.trail_arn }
      }
    },
    {
      Sid       = "AWSCloudTrailWrite"
      Effect    = "Allow"
      Principal = { Service = local.cloudtrail_service }
      Action    = "s3:PutObject"
      Resource  = "${local.bucket_arn}/${var.config.s3_key_prefix == null ? "" : "${var.config.s3_key_prefix}/"}AWSLogs/${local.account_id}/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-acl"  = "bucket-owner-full-control"
          "aws:SourceArn" = local.trail_arn
        }
      }
    },
  ]

  # Trust policy for the CloudTrail -> CloudWatch Logs delivery role.
  cloudtrail_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudTrailAssume"
        Effect    = "Allow"
        Principal = { Service = local.cloudtrail_service }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # Least-privilege delivery policy: only the log stream/event actions CloudTrail
  # needs to deliver to its own log group (PCI DSS Req 7).
  cloudtrail_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailCreateLogStreamAndPut"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "${local.log_group_arn}:*",
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
    description = "CloudTrail CMK for ${var.config.name} (PCI DSS Req 3/10)"
    alias       = "${var.config.name}/cloudtrail"
    # Secure defaults inherited from the atom (rotation on, 30-day window,
    # symmetric ENCRYPT_DECRYPT). We override only the policy so CloudTrail and
    # CloudWatch Logs can use the key (see local.kms_policy).
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- S3 log bucket (the immutable CloudTrail log store) -----------------------
module "log_bucket" {
  source = "../../atoms/s3/s3-bucket"

  config = {
    bucket = local.bucket_name
    # Encrypt with the effective CMK (created or BYO) — never null here.
    kms_key_arn = local.effective_kms_arn
    # Inject the CloudTrail delivery statements; the atom appends them to its
    # own DenyInsecureTransport (TLS-only) statement.
    additional_policy_statements = local.bucket_policy_statements
    tags                         = var.config.tags
    # Secure defaults inherited: encryption on, versioning on, public access
    # blocked, BucketOwnerEnforced ownership.
  }
}

# --- CloudWatch log group (real-time monitoring target, KMS-encrypted) --------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- CloudTrail -> CloudWatch Logs delivery role ------------------------------
module "cloudwatch_role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name_prefix        = "${var.config.name}-ct-cwl-"
    description        = "CloudTrail to CloudWatch Logs delivery role for ${var.config.name}"
    assume_role_policy = local.cloudtrail_assume_role_policy
    inline_policies = {
      "cloudtrail-cwl-delivery" = local.cloudtrail_inline_policy
    }
    tags = var.config.tags
  }
}

# --- The trail, wired to all of the above -------------------------------------
module "trail" {
  source = "../../atoms/cloudtrail/cloudtrail"

  config = {
    name           = local.trail_name
    s3_bucket_name = module.log_bucket.manifest.bucket
    s3_key_prefix  = var.config.s3_key_prefix
    kms_key_arn    = local.effective_kms_arn

    is_organization_trail = var.config.is_organization_trail

    cloud_watch_logs_group_arn = local.cloud_watch_logs_group_arn_for_trail
    cloud_watch_logs_role_arn  = module.cloudwatch_role.manifest.arn

    tags = var.config.tags
    # Secure defaults inherited: multi-region, log file validation, global
    # service events, logging enabled.
  }

  # The trail's create call validates that the bucket policy and CWL role already
  # grant it access; make those dependencies explicit.
  depends_on = [
    module.log_bucket,
    module.cloudwatch_role,
  ]
}
