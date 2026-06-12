locals {
  module_tags = {
    Module = "atoms/acm/acm-certificate" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.config.domain_name
  subject_alternative_names = var.config.subject_alternative_names
  validation_method         = var.config.validation_method
  key_algorithm             = var.config.key_algorithm

  tags = local.tags

  # Issue the replacement cert before destroying the old one so listeners never
  # reference a deleted certificate during rotation.
  lifecycle {
    create_before_destroy = true
  }
}
