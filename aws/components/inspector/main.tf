data "aws_caller_identity" "current" {}

locals {
  # The SNS topic is the findings sink. A BYO key skips the kms-key atom.
  create_topic = var.config.create_notification_topic
  create_kms   = local.create_topic && var.config.kms_key_arn == null

  # Effective CMK ARN handed to the sns-topic atom: created or BYO.
  effective_kms_arn = local.create_topic ? (
    local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
  ) : null

  topic_name = "inspector-findings"

  # ---------------------------------------------------------------------------
  # CMK policy for the findings topic. A future EventBridge rule (no atom yet)
  # will publish Inspector findings to the SNS topic; EventBridge must be able to
  # use the CMK to encrypt the message it delivers. We therefore grant the
  # EventBridge service principal the encrypt/datakey actions (least privilege,
  # PCI DSS Req 7), plus the account root admin (same as the atom default). Only
  # built when this component owns the key.
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
          "kms:Decrypt",
          "kms:GenerateDataKey*",
        ]
        Resource = "*"
      },
    ]
  })
}

# --- Account-level Amazon Inspector v2 enrolment (ECR/EC2/LAMBDA by default) ---
module "inspector" {
  source = "../../atoms/inspector/inspector2-enabler"

  config = {
    resource_types = var.config.resource_types
  }
}

# --- KMS CMK for the findings topic (created only when no BYO key) ------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Inspector findings-notification CMK (PCI DSS Req 3)"
    alias       = "inspector/findings"
    policy      = local.kms_policy
    tags        = var.config.tags
  }
}

# --- Findings-notification SNS topic (CMK-encrypted, TLS-only publish) ---------
# EXPOSED in the manifest; a future EventBridge rule wires Inspector findings to
# it. This component does NOT add the EventBridge rule (no atom exists yet).
module "notification_topic" {
  source = "../../atoms/sns/sns-topic"
  count  = local.create_topic ? 1 : 0

  config = {
    name        = local.topic_name
    kms_key_arn = local.effective_kms_arn
    tags        = var.config.tags
  }
}
