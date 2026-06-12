locals {
  module_tags = {
    Module = "components/sns" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated KMS key only when the caller did not bring their own.
  create_kms_key = var.config.kms_key_arn == null

  # Resolve the CMK ARN fed into the topic: the created atom's key, or the
  # caller-supplied BYOK ARN. Encryption at rest is therefore ALWAYS on.
  kms_key_arn = local.create_kms_key ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
}

# --- KMS key atom (owned by this component, created only when no BYOK) ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms_key ? 1 : 0

  config = {
    description = "SSE-KMS CMK for SNS topic ${var.config.name} (components/sns)"
    alias       = "sns/${var.config.name}"
    tags        = var.config.tags
  }
}

# --- SNS topic atom: KMS-encrypted, TLS-deny policy from the atom ---
module "topic" {
  source = "../../atoms/sns/sns-topic"

  config = {
    name        = var.config.name
    fifo_topic  = var.config.fifo_topic
    kms_key_arn = local.kms_key_arn

    additional_policy_statements = var.config.additional_policy_statements

    tags = var.config.tags
  }
}

# --- Subscription atoms: one per requested subscription, bound to the topic ---
module "subscription" {
  source = "../../atoms/sns/sns-subscription"
  count  = length(var.config.subscriptions)

  config = {
    topic_arn = module.topic.manifest.arn
    protocol  = var.config.subscriptions[count.index].protocol
    endpoint  = var.config.subscriptions[count.index].endpoint

    tags = var.config.tags
  }
}
