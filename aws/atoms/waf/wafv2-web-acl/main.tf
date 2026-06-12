locals {
  module_tags = {
    Module = "atoms/waf/wafv2-web-acl" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Sanitise the ACL name into a CloudWatch-metric-safe base (alnum, _, -).
  metric_base = replace(var.config.name, "/[^A-Za-z0-9_-]/", "-")

  logging_enabled = var.config.log_destination_arn != null
}

resource "aws_wafv2_web_acl" "this" {
  # checkov:skip=CKV_AWS_192: Log4Shell is covered by AWSManagedRulesKnownBadInputsRuleSet, a
  #   default managed_rule_groups entry. Checkov cannot trace rule values supplied through the
  #   config object into the dynamic "rule" blocks; verified present by the secure_defaults test.
  # checkov:skip=CKV_AWS_342: rule override/action is set explicitly per rule (override_action /
  #   action blocks below). Same dynamic-block-through-config limitation as above.
  name        = var.config.name
  description = var.config.description
  scope       = var.config.scope

  default_action {
    dynamic "allow" {
      for_each = var.config.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.config.default_action == "block" ? [1] : []
      content {}
    }
  }

  # AWS-managed rule groups (PCI DSS Req 6.4.1 / 6.4.2: address common attacks).
  dynamic "rule" {
    for_each = { for g in var.config.managed_rule_groups : g.name => g }
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_to_count ? [] : [1]
          content {}
        }
        dynamic "count" {
          for_each = rule.value.override_to_count ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.metric_base}-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  # Optional rate-based rule (PCI DSS Req 6.4.x: throttle abusive sources).
  dynamic "rule" {
    for_each = var.config.rate_limit == null ? [] : [var.config.rate_limit]
    content {
      name     = "${var.config.name}-rate-limit"
      priority = 100

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = rule.value
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.metric_base}-rate-limit"
        sampled_requests_enabled   = true
      }
    }
  }

  # Caller-authored custom rules, passed through verbatim.
  dynamic "rule" {
    for_each = var.config.custom_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = try(rule.value.action, null) == null ? [] : [rule.value.action]
        content {
          dynamic "allow" {
            for_each = try(action.value.allow, null) == null ? [] : [1]
            content {}
          }
          dynamic "block" {
            for_each = try(action.value.block, null) == null ? [] : [1]
            content {}
          }
          dynamic "count" {
            for_each = try(action.value.count, null) == null ? [] : [1]
            content {}
          }
        }
      }

      statement {
        dynamic "byte_match_statement" {
          for_each = try(rule.value.byte_match_statement, null) == null ? [] : [rule.value.byte_match_statement]
          content {
            positional_constraint = byte_match_statement.value.positional_constraint
            search_string         = byte_match_statement.value.search_string
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.metric_base}-${rule.value.name}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.metric_base
    sampled_requests_enabled   = true
  }

  tags = local.tags

  # Request logging must be configured; weakening it must be intentional and
  # auditable (PCI DSS Req 10: track and monitor all access).
  lifecycle {
    precondition {
      condition     = local.logging_enabled || var.config.allow_logging_disabled
      error_message = "Logging not configured (config.log_destination_arn is null) without config.allow_logging_disabled=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Tightly-coupled logging sub-resource — meaningless without the ACL above.
resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = local.logging_enabled ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.this.arn
  log_destination_configs = [var.config.log_destination_arn]
}
