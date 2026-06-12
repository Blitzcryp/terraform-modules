locals {
  module_tags = {
    Module = "atoms/s3/s3-bucket" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # SSE-KMS by default (never plain AES256). A caller-supplied CMK is used when
  # provided; otherwise the AWS-managed aws:kms key is used.
  sse_algorithm = "aws:kms"

  # Deny all non-TLS access (PCI DSS Req 4: encrypt transmission). Callers may
  # append further statements via config.additional_policy_statements.
  deny_insecure_transport = {
    Sid       = "DenyInsecureTransport"
    Effect    = "Deny"
    Principal = "*"
    Action    = "s3:*"
    Resource = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
    Condition = {
      Bool = { "aws:SecureTransport" = "false" }
    }
  }

  policy_statements = concat([local.deny_insecure_transport], var.config.additional_policy_statements)
}

resource "aws_s3_bucket" "this" {
  bucket = var.config.bucket
  tags   = local.tags

  lifecycle {
    # Encryption at rest must be intentional to disable (PCI DSS Req 3).
    precondition {
      condition     = var.config.enable_encryption || var.config.allow_unencrypted
      error_message = "Encryption disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # Versioning protects integrity/availability (PCI DSS Req 10).
    precondition {
      condition     = var.config.enable_versioning || var.config.allow_unversioned
      error_message = "Versioning disabled without config.allow_unversioned=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # Public exposure must be intentional (PCI DSS Req 1/7).
    precondition {
      condition     = var.config.block_public_access || var.config.allow_public_access
      error_message = "Public access block disabled without config.allow_public_access=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.config.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = var.config.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.config.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  # checkov:skip=CKV_AWS_53: all four flags default to true via config.block_public_access
  # checkov:skip=CKV_AWS_54: (optional(bool, true)); checkov cannot statically resolve the
  # checkov:skip=CKV_AWS_55: value through the config object, but the secure default is
  # checkov:skip=CKV_AWS_56: enforced by the secure_defaults test. Relaxing it requires the
  # auditable config.allow_public_access escape hatch (PCI DSS Req 1/7).
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.config.block_public_access
  block_public_policy     = var.config.block_public_access
  ignore_public_acls      = var.config.block_public_access
  restrict_public_buckets = var.config.block_public_access
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.config.object_ownership
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.policy_statements
  })

  # The policy references the public access block's intent; apply it first so a
  # locked-down bucket does not transiently reject our own policy put.
  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_logging" "this" {
  count         = var.config.logging_target_bucket == null ? 0 : 1
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.config.logging_target_bucket
  target_prefix = var.config.logging_target_prefix
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # checkov:skip=CKV_AWS_300: abort-incomplete-multipart period is exposed to the
  # caller via config.lifecycle_rules[*].abort_incomplete_multipart_upload_days;
  # checkov cannot statically resolve the optional dynamic block.
  count  = length(var.config.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.config.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        prefix = rule.value.prefix == null ? "" : rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days == null ? [] : [rule.value.expiration_days]
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days == null ? [] : [rule.value.noncurrent_version_expiration_days]
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days == null ? [] : [rule.value.abort_incomplete_multipart_upload_days]
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }

  # Lifecycle rules apply to versions, so versioning must settle first.
  depends_on = [aws_s3_bucket_versioning.this]
}
