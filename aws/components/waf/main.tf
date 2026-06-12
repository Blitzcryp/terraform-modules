data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/waf" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Whether this component owns the CMK. A BYO key ARN skips the kms-key atom.
  create_kms = var.config.kms_key_arn == null

  # The three AWS baseline managed rule groups (Common, KnownBadInputs incl.
  # Log4Shell coverage, SQLi). Resolved here so the secure default is explicit
  # at the component layer and statically auditable, rather than relying on the
  # atom's runtime default substitution. Callers may override via config.
  baseline_managed_rule_groups = [
    { name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS", priority = 0, override_to_count = false },
    { name = "AWSManagedRulesKnownBadInputsRuleSet", vendor_name = "AWS", priority = 1, override_to_count = false },
    { name = "AWSManagedRulesSQLiRuleSet", vendor_name = "AWS", priority = 2, override_to_count = false },
  ]
  effective_managed_rule_groups = [
    for g in(var.config.managed_rule_groups == null ? local.baseline_managed_rule_groups : var.config.managed_rule_groups) : {
      name              = g.name
      vendor_name       = g.vendor_name
      priority          = g.priority
      override_to_count = g.override_to_count
    }
  ]

  # WAFv2 logging to CloudWatch Logs requires the log group name to start with
  # the reserved `aws-waf-logs-` prefix (hard AWS requirement).
  log_group_name = "aws-waf-logs-${var.config.name}"

  # The log group ARN the Web ACL logs to. Computed (not the atom's output) so it
  # is known at plan time; the atom's logging-config `count` keys off this value
  # and must not depend on a computed attribute. This is the canonical CloudWatch
  # Logs ARN format for the log group this component creates.
  log_group_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"

  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  logs_service_principal = "logs.${data.aws_region.current.name}.amazonaws.com"

  # ---------------------------------------------------------------------------
  # CRITICAL CORRECTNESS (apply-time): a CloudWatch log group encrypted with a
  # customer-managed CMK fails to create unless the key policy grants the
  # regional CloudWatch Logs service principal (logs.<region>.amazonaws.com)
  # permission to use the key. Mirrors aws/components/audit-logging. Only used
  # when this component creates the key (BYO keys are the caller's to authorise).
  # ---------------------------------------------------------------------------
  kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = local.logs_service_principal }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Component-level retention guard (trivial glue, no AWS resource). WAF request
# logs are part of the audit trail and must be retained long enough to be useful
# for investigations (PCI DSS Req 10.5.1: >= 3 months readily available). The
# cloudwatch-log-group atom validates only that the value is a legal CloudWatch
# retention; this guard enforces the component's minimum. Surfaced as a checkable
# resource so a too-short retention fails the plan.
# -----------------------------------------------------------------------------
resource "terraform_data" "retention_guard" {
  input = var.config.log_retention_days

  lifecycle {
    precondition {
      condition     = var.config.log_retention_days == 0 || var.config.log_retention_days >= 90
      error_message = "config.log_retention_days must be >= 90 days (PCI DSS Req 10.5.1) or 0 for never-expire."
    }
  }
}

# --- KMS CMK for log encryption (created only when no BYO key is supplied) ----
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "WAF request-log CMK for ${var.config.name} (PCI DSS Req 10)"
    alias       = "waf/${var.config.name}"
    # Secure defaults inherited from the atom (rotation on, 30-day window). We
    # override only the policy so the regional CloudWatch Logs service can use it.
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- KMS-encrypted CloudWatch log group (the WAF log destination) -------------
module "log_group" {
  source = "../../atoms/cloudwatch/cloudwatch-log-group"

  config = {
    name              = local.log_group_name
    kms_key_arn       = local.effective_kms_arn
    retention_in_days = var.config.log_retention_days
    tags              = var.config.tags
  }
}

# --- The WAFv2 Web ACL ---------------------------------------------------------
module "web_acl" {
  source = "../../atoms/waf/wafv2-web-acl"

  config = {
    name  = var.config.name
    scope = var.config.scope

    # Always pass a concrete list (the baseline groups by default) so the secure
    # default is explicit and statically auditable through composition.
    managed_rule_groups = local.effective_managed_rule_groups

    rate_limit = var.config.rate_limit

    # Logging on by default (PCI DSS Req 10): point the ACL at the encrypted
    # log group. We use the plan-time-known ARN (local.log_group_arn) rather than
    # the atom's computed output so the atom's logging-config count is resolvable
    # at plan. depends_on ensures the group exists before the ACL logging config.
    log_destination_arn = local.log_group_arn

    tags = var.config.tags
  }

  # The ACL's logging configuration targets local.log_group_arn (a derived ARN),
  # so make the dependency on the actual log group explicit.
  depends_on = [module.log_group]
}

# --- Optional associations to regional resources -----------------------------
module "associations" {
  source = "../../atoms/waf/wafv2-web-acl-association"
  count  = length(var.config.associate_resource_arns)

  config = {
    web_acl_arn  = module.web_acl.manifest.arn
    resource_arn = var.config.associate_resource_arns[count.index]
    tags         = var.config.tags
  }
}
