data "aws_region" "current" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/cspm" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Whether this component owns the CMK. A BYO key ARN skips kms-key creation;
  # the supplied key then encrypts the Config delivery bucket.
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # AWS Config delivery bucket name. Globally unique-ish: prefix + account id.
  config_bucket_name = "${var.config.name_prefix}-config-${local.account_id}"

  # The AWS managed policy granting AWS Config its required read/describe perms.
  config_managed_policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWS_ConfigRole"

  # Config service role trust policy (PCI DSS Req 8: identify the principal).
  config_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowConfigAssume"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # ---------------------------------------------------------------------------
  # APPLY-TIME CORRECTNESS: the AWS Config delivery channel cannot write to the
  # S3 bucket unless the bucket policy explicitly authorises the AWS Config
  # service principal. We therefore attach (via the s3-bucket atom's
  # additional_policy_statements) the canonical AWS Config bucket policy:
  #   (a) GetBucketAcl + ListBucket on the bucket, and
  #   (b) PutObject under AWSLogs/<account>/Config/* requiring the
  #       bucket-owner-full-control ACL.
  # The statements are scoped to this account via the AWS:SourceAccount /
  # s3:x-amz-acl conditions (least privilege). The bucket itself is created here
  # private + encrypted; this policy is the documented assumption for delivery.
  # ---------------------------------------------------------------------------
  config_service_principal = "config.amazonaws.com"
  config_bucket_arn        = "arn:${local.partition}:s3:::${local.config_bucket_name}"

  config_bucket_policy_statements = [
    {
      Sid       = "AWSConfigBucketPermissionsCheck"
      Effect    = "Allow"
      Principal = { Service = local.config_service_principal }
      Action    = ["s3:GetBucketAcl", "s3:ListBucket"]
      Resource  = local.config_bucket_arn
      Condition = {
        StringEquals = { "AWS:SourceAccount" = local.account_id }
      }
    },
    {
      Sid       = "AWSConfigBucketDelivery"
      Effect    = "Allow"
      Principal = { Service = local.config_service_principal }
      Action    = "s3:PutObject"
      Resource  = "${local.config_bucket_arn}/AWSLogs/${local.account_id}/Config/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-acl"      = "bucket-owner-full-control"
          "AWS:SourceAccount" = local.account_id
        }
      }
    },
  ]
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
# Encrypts the AWS Config delivery bucket; available to the posture services.
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "CSPM CMK for ${var.config.name_prefix} (PCI DSS Req 3 — encrypts the AWS Config delivery bucket)"
    alias       = "${var.config.name_prefix}/cspm"
    # Secure defaults inherited: rotation on, 30-day window, symmetric.
    tags = var.config.tags
  }
}

# --- AWS Config delivery bucket (private, encrypted) --------------------------
# Created only when AWS Config is enabled. The Config service bucket policy is
# attached via additional_policy_statements (see local notes above).
module "config_bucket" {
  source = "../../atoms/s3/s3-bucket"
  count  = var.config.enable_config ? 1 : 0

  config = {
    bucket                       = local.config_bucket_name
    kms_key_arn                  = local.effective_kms_arn
    additional_policy_statements = local.config_bucket_policy_statements
    tags                         = var.config.tags
    # enable_encryption / enable_versioning / block_public_access inherit secure
    # defaults from the atom (true).
  }
}

# --- AWS Config service role --------------------------------------------------
# Created only when AWS Config is enabled. Trusts config.amazonaws.com and
# attaches the AWS managed AWS_ConfigRole policy.
module "config_role" {
  source = "../../atoms/iam/iam-role"
  count  = var.config.enable_config ? 1 : 0

  config = {
    name_prefix         = "${var.config.name_prefix}-config-"
    description         = "AWS Config service role for ${var.config.name_prefix} CSPM baseline"
    assume_role_policy  = local.config_assume_role_policy
    managed_policy_arns = [local.config_managed_policy_arn]
    tags                = var.config.tags
  }
}

# --- AWS Config recorder + delivery channel + status --------------------------
module "config_recorder" {
  source = "../../atoms/config/config-recorder"
  count  = var.config.enable_config ? 1 : 0

  config = {
    name           = "${var.config.name_prefix}-cspm"
    s3_bucket_name = module.config_bucket[0].manifest.bucket
    iam_role_arn   = module.config_role[0].manifest.arn
    # record_all_resources / include_global_resource_types inherit secure
    # defaults from the atom (true).
    tags = var.config.tags
  }
}

# --- Security Hub account enabler + standards subscriptions -------------------
module "security_hub" {
  source = "../../atoms/securityhub/securityhub-account"
  count  = var.config.enable_security_hub ? 1 : 0

  config = {
    # enable_default_standards / control_finding_generator / auto_enable_controls
    # inherit secure defaults from the atom.
    tags = var.config.tags
  }
}

# --- GuardDuty detector + protection features ---------------------------------
module "guardduty" {
  source = "../../atoms/guardduty/guardduty-detector"
  count  = var.config.enable_guardduty ? 1 : 0

  config = {
    # enable / frequency / S3 + malware protection inherit secure defaults.
    tags = var.config.tags
  }
}

# --- Inspector v2 enabler -----------------------------------------------------
module "inspector" {
  source = "../../atoms/inspector/inspector2-enabler"
  count  = var.config.enable_inspector ? 1 : 0

  config = {
    resource_types = var.config.inspector_resource_types
  }
}
