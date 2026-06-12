locals {
  module_tags = {
    Module = "atoms/alb/alb" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_lb" "this" {
  # checkov:skip=CKV_AWS_131: drop_invalid_header_fields defaults to true
  # checkov:skip=CKV_AWS_150: enable_deletion_protection defaults to true
  # checkov:skip=CKV_AWS_152: cross-zone applies to NLB/GWLB, not this ALB default;
  #   all three controls are optional(bool, true) on config and checkov cannot
  #   statically resolve the value through the config object. The secure default
  #   is enforced by the secure_defaults test; relaxing requires an explicit flag.
  name               = var.config.name
  load_balancer_type = var.config.load_balancer_type
  internal           = var.config.internal
  subnets            = var.config.subnets
  security_groups    = var.config.security_groups
  idle_timeout       = var.config.idle_timeout

  # PCI DSS Req 1/4/10 secure controls.
  drop_invalid_header_fields = var.config.drop_invalid_header_fields
  enable_deletion_protection = var.config.enable_deletion_protection
  desync_mitigation_mode     = var.config.desync_mitigation_mode

  dynamic "access_logs" {
    for_each = var.config.access_logs_bucket == null ? [] : [1]
    content {
      enabled = true
      bucket  = var.config.access_logs_bucket
      prefix  = var.config.access_logs_prefix
    }
  }

  tags = local.tags

  lifecycle {
    # Internet-facing exposure must be intentional (PCI DSS Req 1: limit inbound/outbound).
    precondition {
      condition     = var.config.internal || var.config.allow_internet_facing
      error_message = "Internet-facing ALB (internal=false) requires config.allow_internet_facing=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
