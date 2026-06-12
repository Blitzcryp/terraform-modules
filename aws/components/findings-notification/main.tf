data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "components/findings-notification" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated CMK only when the caller did not bring their own.
  create_kms  = var.config.kms_key_arn == null
  kms_key_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  topic_name = "${var.config.name}-findings"
  rule_name  = "${var.config.name}-findings"

  # ---------------------------------------------------------------------------
  # Event patterns per supported security service. Each entry is a {source,
  # detail-type} pair as emitted to the default event bus.
  # ---------------------------------------------------------------------------
  source_patterns = {
    securityhub = { source = "aws.securityhub", detail-type = "Security Hub Findings - Imported" }
    inspector   = { source = "aws.inspector2", detail-type = "Inspector2 Finding" }
    guardduty   = { source = "aws.guardduty", detail-type = "GuardDuty Finding" }
  }

  selected = var.config.source == "all" ? ["securityhub", "inspector", "guardduty"] : [var.config.source]

  derived_event_pattern = jsonencode({
    source      = distinct([for s in local.selected : local.source_patterns[s].source])
    detail-type = distinct([for s in local.selected : local.source_patterns[s].detail-type])
  })

  # The full event_pattern override wins when supplied.
  event_pattern = coalesce(var.config.additional_event_pattern, local.derived_event_pattern)

  # ---------------------------------------------------------------------------
  # CMK key policy: account-root admin (atom default) PLUS EventBridge so the
  # service can encrypt messages it publishes to the encrypted SNS topic
  # (least privilege, PCI DSS Req 7). Only built when this component owns the key.
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
        Sid       = "AllowEventBridgeUseOfKey"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey*",
        ]
        Resource = "*"
      },
    ]
  })

  # ---------------------------------------------------------------------------
  # Extra SNS topic-policy statement: EventBridge must be allowed to publish to
  # the (encrypted) topic. Injected via the sns-topic atom's
  # additional_policy_statements (Resource is the topic ARN, resolved by the atom
  # at apply time so we use a wildcard-safe condition on the topic name instead).
  # ---------------------------------------------------------------------------
  events_publish_statement = {
    Sid       = "AllowEventBridgePublish"
    Effect    = "Allow"
    Principal = { Service = "events.amazonaws.com" }
    Action    = "SNS:Publish"
    Resource  = "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${local.topic_name}"
  }
}

# --- KMS CMK for the findings topic (created only when no BYO key) ------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "findings-notification CMK for ${local.topic_name} (PCI DSS Req 3)"
    alias       = "findings-notification/${var.config.name}"
    policy      = local.kms_policy
    tags        = var.config.tags
  }
}

# --- Findings-notification SNS topic: CMK-encrypted, TLS-deny + EventBridge ---
module "topic" {
  source = "../../atoms/sns/sns-topic"

  config = {
    name        = local.topic_name
    kms_key_arn = local.kms_key_arn

    # Allow the EventBridge service to publish into the encrypted topic.
    additional_policy_statements = [local.events_publish_statement]

    tags = var.config.tags
  }
}

# --- EventBridge rule selecting findings by source ----------------------------
module "rule" {
  source = "../../atoms/eventbridge/event-rule"

  config = {
    name          = local.rule_name
    description   = "Route ${var.config.source} security findings to SNS (components/findings-notification)"
    event_pattern = local.event_pattern
    tags          = var.config.tags
  }
}

# --- EventBridge target wiring the rule to the SNS topic ----------------------
module "target" {
  source = "../../atoms/eventbridge/event-target"

  config = {
    rule      = module.rule.manifest.name
    arn       = module.topic.manifest.arn
    target_id = "${var.config.name}-sns"
    tags      = var.config.tags
  }
}
