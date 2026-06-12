locals {
  # This atom owns a single association resource which is not taggable. We still
  # accept config.tags on the object for interface uniformity with every other
  # atom; the module-identity tag is documented here for traceability even though
  # it cannot be applied to the resource.
  module_tags = {
    Module = "atoms/waf/wafv2-web-acl-association" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_wafv2_web_acl_association" "this" {
  web_acl_arn  = var.config.web_acl_arn
  resource_arn = var.config.resource_arn
}
