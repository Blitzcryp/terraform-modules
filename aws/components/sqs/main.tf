locals {
  module_tags = {
    Module = "components/sqs" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Create a dedicated KMS key only when the caller did not bring their own.
  create_kms_key = var.config.kms_key_arn == null

  # Resolve the CMK ARN fed into the queue: the created atom's key, or the
  # caller-supplied BYOK ARN. Encryption at rest is therefore ALWAYS on with a CMK.
  kms_key_arn = local.create_kms_key ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
}

# --- KMS key atom (owned by this component, created only when no BYOK) ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms_key ? 1 : 0

  config = {
    description = "SSE-KMS CMK for SQS queue ${var.config.name} (components/sqs)"
    alias       = "sqs/${var.config.name}"
    tags        = var.config.tags
  }
}

# --- SQS queue atom: KMS-encrypted, DLQ on, TLS-deny policy from the atom ---
module "queue" {
  source = "../../atoms/sqs/sqs-queue"

  config = {
    name        = var.config.name
    fifo_queue  = var.config.fifo_queue
    kms_key_arn = local.kms_key_arn

    enable_dlq        = var.config.enable_dlq
    max_receive_count = var.config.max_receive_count

    message_retention_seconds = var.config.message_retention_seconds

    additional_policy_statements = var.config.additional_policy_statements

    tags = var.config.tags
  }
}
