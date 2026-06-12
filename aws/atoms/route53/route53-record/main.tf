locals {
  # local.tags is kept for uniformity with other atoms, but aws_route53_record
  # does NOT support tags — DNS records are not taggable AWS resources. The tags
  # are intentionally not applied to any resource here; they are accepted so this
  # atom's config shape matches the rest of the library.
  module_tags = {
    Module = "atoms/route53/route53-record"
  }
  tags = merge(local.module_tags, var.config.tags)

  is_alias = var.config.alias != null
}

resource "aws_route53_record" "this" {
  zone_id         = var.config.zone_id
  name            = var.config.name
  type            = var.config.type
  allow_overwrite = var.config.allow_overwrite

  # Standard record: ttl + records. Omitted entirely for alias records.
  ttl     = local.is_alias ? null : var.config.ttl
  records = local.is_alias ? null : var.config.records

  # Alias record: points at an AWS resource (ALB, CloudFront, S3 website, etc.).
  dynamic "alias" {
    for_each = local.is_alias ? [var.config.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}
