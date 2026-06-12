locals {
  # Create a dedicated KMS key only when the caller did not bring their own.
  create_kms_key = var.config.kms_key_arn == null

  # Create a companion log bucket only when access logging is on AND no external
  # log bucket was supplied.
  create_log_bucket = var.config.enable_access_logging && var.config.access_log_bucket == null

  # Resolve the KMS key ARN fed into the main bucket: the created atom's key, or
  # the caller-supplied BYOK ARN.
  kms_key_arn = local.create_kms_key ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  # Resolve the logging target the main bucket points at:
  #  - logging disabled            -> null (no logging configured)
  #  - external bucket supplied    -> use it directly
  #  - companion bucket created    -> use the companion bucket's name
  logging_target_bucket = (
    !var.config.enable_access_logging ? null :
    local.create_log_bucket ? module.log_bucket[0].manifest.bucket :
    var.config.access_log_bucket
  )

  # Companion log bucket name derived from the main bucket name.
  log_bucket_name = "${var.config.bucket}-logs"
}

# --- KMS key atom (owned by this component, created only when no BYOK) ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms_key ? 1 : 0

  config = {
    description = "SSE-KMS CMK for S3 bucket ${var.config.bucket} (private-encrypted-bucket)"
    alias       = "s3/${var.config.bucket}"
    tags        = var.config.tags
  }
}

# --- Companion access-log bucket atom (created only when logging on & no external) ---
module "log_bucket" {
  source = "../../atoms/s3/s3-bucket"
  count  = local.create_log_bucket ? 1 : 0

  config = {
    bucket = local.log_bucket_name

    # SSE-KMS with the same key resolution as the main bucket.
    enable_encryption = true
    kms_key_arn       = local.kms_key_arn

    enable_versioning   = true
    block_public_access = true

    # Disable logging on the log bucket itself to avoid recursion.
    logging_target_bucket = null

    tags = var.config.tags
  }
}

# --- Main bucket atom: SSE-KMS, versioned, public access blocked, TLS-only ---
module "bucket" {
  source = "../../atoms/s3/s3-bucket"

  config = {
    bucket = var.config.bucket

    enable_encryption = true
    kms_key_arn       = local.kms_key_arn

    enable_versioning   = var.config.enable_versioning
    block_public_access = true

    logging_target_bucket = local.logging_target_bucket
    logging_target_prefix = var.config.access_log_prefix

    lifecycle_rules              = var.config.lifecycle_rules
    additional_policy_statements = var.config.additional_policy_statements

    tags = var.config.tags
  }
}
