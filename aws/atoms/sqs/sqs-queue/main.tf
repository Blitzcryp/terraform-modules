locals {
  module_tags = {
    Module = "atoms/sqs/sqs-queue" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # PCI DSS Req 3: encryption at rest is ALWAYS on unless explicitly disabled.
  # Prefer a customer-managed KMS key; fall back to SSE-SQS when no CMK given.
  use_kms = var.config.kms_key_arn != null
  # SSE-SQS is enabled only when there is no CMK and encryption is not disabled.
  sse_sqs_enabled = !local.use_kms && !var.config.allow_unencrypted

  # DLQ names mirror the main queue and keep the '.fifo' suffix when required.
  dlq_name = var.config.fifo_queue ? "${trimsuffix(var.config.name, ".fifo")}-dlq.fifo" : "${var.config.name}-dlq"

  enable_dlq = var.config.enable_dlq

  # PCI DSS Req 4: deny any action against the queue over a non-TLS transport.
  tls_deny_statement = {
    Sid       = "DenyAccessOverNonTLS"
    Effect    = "Deny"
    Principal = { AWS = "*" }
    Action    = "sqs:*"
    Resource  = aws_sqs_queue.this.arn
    Condition = {
      Bool = { "aws:SecureTransport" = "false" }
    }
  }

  queue_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([local.tls_deny_statement], tolist(var.config.additional_policy_statements))
  })
}

# Companion dead-letter queue. Tightly coupled: created and encrypted with the
# same controls as the primary queue, and meaningless without it.
resource "aws_sqs_queue" "dlq" {
  count = local.enable_dlq ? 1 : 0

  name       = local.dlq_name
  fifo_queue = var.config.fifo_queue

  message_retention_seconds = var.config.message_retention_seconds

  kms_master_key_id = var.config.kms_key_arn
  # Set only when SSE-SQS is the chosen mode; omit (null) otherwise so it does
  # not conflict with kms_master_key_id when a CMK is supplied.
  sqs_managed_sse_enabled = local.sse_sqs_enabled ? true : null

  tags = local.tags

  lifecycle {
    precondition {
      condition     = local.use_kms || local.sse_sqs_enabled || var.config.allow_unencrypted
      error_message = "DLQ would be unencrypted. Provide config.kms_key_arn (CMK) — SSE-SQS is the automatic fallback — or file a PCI exception (security@emag.ro) and set config.allow_unencrypted=true."
    }
  }
}

resource "aws_sqs_queue" "this" {
  name       = var.config.name
  fifo_queue = var.config.fifo_queue

  message_retention_seconds = var.config.message_retention_seconds

  # PCI DSS Req 3: CMK when supplied, otherwise SSE-SQS fallback (never off).
  kms_master_key_id = var.config.kms_key_arn
  # Set only when SSE-SQS is the chosen mode; omit (null) otherwise so it does
  # not conflict with kms_master_key_id when a CMK is supplied.
  sqs_managed_sse_enabled = local.sse_sqs_enabled ? true : null

  redrive_policy = local.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.config.max_receive_count
  }) : null

  tags = local.tags

  # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
  lifecycle {
    precondition {
      condition     = local.use_kms || local.sse_sqs_enabled || var.config.allow_unencrypted
      error_message = "Queue would be unencrypted. Provide config.kms_key_arn (CMK) — SSE-SQS is the automatic fallback — or file a PCI exception (security@emag.ro) and set config.allow_unencrypted=true."
    }
  }
}

# Tightly-coupled sub-resource: a queue policy is meaningless without its queue.
resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.url
  policy    = local.queue_policy
}
