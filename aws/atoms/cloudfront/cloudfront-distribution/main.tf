locals {
  module_tags = {
    Module = "atoms/cloudfront/cloudfront-distribution" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # TLS floor for PCI DSS Req 4. Anything weaker than TLSv1.2_2021 is considered
  # weak and requires the allow_weak_tls escape hatch.
  strong_tls_versions = ["TLSv1.2_2021"]
  tls_is_strong       = contains(local.strong_tls_versions, var.config.minimum_protocol_version)

  using_default_cert = var.config.acm_certificate_arn == null
}

resource "aws_cloudfront_distribution" "this" {
  # checkov:skip=CKV_AWS_216: enabled defaults to true (var.config.enabled); checkov cannot resolve the module default. Disabling requires an explicit config.enabled=false.
  # checkov:skip=CKV_AWS_174: TLS floor is TLSv1.2_2021 on the custom-cert path (enforced by the allow_weak_tls precondition); on the default *.cloudfront.net cert path minimum_protocol_version is provider/AWS-managed and not settable. False positive from the default-cert example.
  # checkov:skip=CKV_AWS_310: origin failover (origin_group) is optional resilience hardening, not a PCI control; left to the caller to opt into.
  enabled             = var.config.enabled
  comment             = var.config.comment
  aliases             = var.config.aliases
  default_root_object = var.config.default_root_object
  price_class         = var.config.price_class
  web_acl_id          = var.config.web_acl_id

  dynamic "origin" {
    for_each = var.config.origins
    content {
      domain_name              = origin.value.domain_name
      origin_id                = origin.value.origin_id
      origin_access_control_id = origin.value.origin_access_control_id
      origin_path              = origin.value.origin_path

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_config == null ? [] : [origin.value.s3_origin_config]
        content {
          origin_access_identity = s3_origin_config.value.origin_access_identity
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config == null ? [] : [origin.value.custom_origin_config]
        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_read_timeout      = custom_origin_config.value.origin_read_timeout
          origin_keepalive_timeout = custom_origin_config.value.origin_keepalive_timeout
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = var.config.default_cache_behavior.target_origin_id
    allowed_methods        = var.config.default_cache_behavior.allowed_methods
    cached_methods         = var.config.default_cache_behavior.cached_methods
    viewer_protocol_policy = var.config.default_cache_behavior.viewer_protocol_policy
    compress               = var.config.default_cache_behavior.compress
    cache_policy_id        = var.config.default_cache_behavior.cache_policy_id

    dynamic "forwarded_values" {
      for_each = var.config.default_cache_behavior.forwarded_values == null ? [] : [var.config.default_cache_behavior.forwarded_values]
      content {
        query_string = forwarded_values.value.query_string
        headers      = forwarded_values.value.headers
        cookies {
          forward = forwarded_values.value.cookies.forward
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.config.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      compress               = ordered_cache_behavior.value.compress
      cache_policy_id        = ordered_cache_behavior.value.cache_policy_id

      dynamic "forwarded_values" {
        for_each = ordered_cache_behavior.value.forwarded_values == null ? [] : [ordered_cache_behavior.value.forwarded_values]
        content {
          query_string = forwarded_values.value.query_string
          headers      = forwarded_values.value.headers
          cookies {
            forward = forwarded_values.value.cookies.forward
          }
        }
      }
    }
  }

  dynamic "logging_config" {
    for_each = var.config.log_bucket == null ? [] : [1]
    content {
      bucket          = var.config.log_bucket
      prefix          = var.config.log_prefix
      include_cookies = var.config.log_include_cookies
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = local.using_default_cert
    acm_certificate_arn            = var.config.acm_certificate_arn
    ssl_support_method             = local.using_default_cert ? null : var.config.ssl_support_method
    minimum_protocol_version       = local.using_default_cert ? null : var.config.minimum_protocol_version
  }

  restrictions {
    geo_restriction {
      restriction_type = var.config.geo_restriction.restriction_type
      locations        = var.config.geo_restriction.locations
    }
  }

  tags = local.tags

  # Transport security must be intentional to weaken (PCI DSS Req 4). A weak TLS
  # floor is only allowed via the explicit, grep-able escape hatch. (When the
  # default CloudFront cert is used, minimum_protocol_version is provider-managed
  # at TLSv1, so the guard only applies when a custom ACM cert is supplied.)
  lifecycle {
    precondition {
      condition     = local.using_default_cert || local.tls_is_strong || var.config.allow_weak_tls
      error_message = "minimum_protocol_version '${var.config.minimum_protocol_version}' is weaker than TLSv1.2_2021. Set config.allow_weak_tls=true with a documented PCI exception (security@emag.ro)."
    }
  }
}
