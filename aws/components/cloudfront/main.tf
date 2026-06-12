locals {
  module_tags = {
    Module = "components/cloudfront" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  is_s3_origin = var.config.s3_origin_domain_name != null
  origin_id    = "${var.config.name}-origin"

  # Create an OAC only for S3 origins (it locks the private bucket to CloudFront).
  create_oac = local.is_s3_origin

  # The single origin domain (exactly one of the two is set; enforced by validation).
  origin_domain_name = coalesce(var.config.s3_origin_domain_name, var.config.custom_origin_domain_name)

  # Owned access-log bucket: created when logging is on and no BYO bucket given.
  create_log_bucket = var.config.enable_logging && var.config.log_bucket == null
  log_bucket_name   = "${var.config.name}-cf-logs"

  # The CloudFront logging_config bucket field wants the S3 bucket DOMAIN NAME.
  effective_log_bucket_domain = (
    !var.config.enable_logging ? null :
    local.create_log_bucket ? module.log_bucket[0].manifest.bucket_domain_name :
    var.config.log_bucket
  )

  # Manifest convenience: the owned log bucket NAME (null when disabled / BYO).
  owned_log_bucket_name = local.create_log_bucket ? module.log_bucket[0].manifest.bucket : null
}

# -----------------------------------------------------------------------------
# Origin Access Control (S3 origins only). Lets CloudFront sign origin requests
# with SigV4 so the bucket can stay fully private (no public access) — PCI Req 1/7.
# -----------------------------------------------------------------------------
module "oac" {
  source = "../../atoms/cloudfront/cloudfront-origin-access-control"
  count  = local.create_oac ? 1 : 0

  config = {
    name        = "${var.config.name}-oac"
    description = "OAC for ${var.config.name} S3 origin (components/cloudfront)"
  }
}

# -----------------------------------------------------------------------------
# Access-log bucket (created only when logging is on and no BYO bucket given).
# CAVEAT: CloudFront standard logging requires ACLs enabled on the target bucket,
# so this bucket overrides the atom's BucketOwnerEnforced default with
# BucketOwnerPreferred. The log-delivery ACL grant must still be applied out of
# band (or use a BYO bucket / CloudFront v2 logging). See variables.tf.
# -----------------------------------------------------------------------------
module "log_bucket" {
  source = "../../atoms/s3/s3-bucket"
  count  = local.create_log_bucket ? 1 : 0

  config = {
    bucket           = local.log_bucket_name
    object_ownership = "BucketOwnerPreferred" # CloudFront standard logging needs ACLs enabled
    tags             = var.config.tags
  }
}

# -----------------------------------------------------------------------------
# The CloudFront distribution: TLS 1.2+, redirect-to-https, OAC for S3, WAF +
# ACM cert passed through as inputs, logging wired to the resolved bucket domain.
# -----------------------------------------------------------------------------
module "distribution" {
  source = "../../atoms/cloudfront/cloudfront-distribution"

  config = {
    comment             = "CloudFront distribution ${var.config.name} (components/cloudfront)"
    aliases             = var.config.aliases
    default_root_object = var.config.default_root_object
    price_class         = var.config.price_class

    acm_certificate_arn = var.config.acm_certificate_arn
    web_acl_id          = var.config.web_acl_arn

    origins = [
      {
        domain_name              = local.origin_domain_name
        origin_id                = local.origin_id
        origin_access_control_id = local.create_oac ? module.oac[0].manifest.id : null
        # S3 origins behind an OAC still require an (empty) s3_origin_config block;
        # custom origins use a custom_origin_config (HTTPS-only to the origin).
        s3_origin_config     = local.is_s3_origin ? {} : null
        custom_origin_config = local.is_s3_origin ? null : {}
      }
    ]

    default_cache_behavior = {
      target_origin_id = local.origin_id
      allowed_methods  = ["GET", "HEAD", "OPTIONS"]
      cached_methods   = ["GET", "HEAD"]
      # Secure default inherited from the atom: redirect-to-https, TLS 1.2+.
      forwarded_values = {
        query_string = false
        cookies      = { forward = "none" }
      }
    }

    log_bucket = local.effective_log_bucket_domain

    tags = var.config.tags
  }
}
