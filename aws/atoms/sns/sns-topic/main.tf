locals {
  module_tags = {
    Module = "atoms/sns/sns-topic" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # PCI DSS Req 4: deny any Publish to this topic that is not over TLS.
  tls_deny_statement = {
    Sid       = "DenyPublishOverNonTLS"
    Effect    = "Deny"
    Principal = { AWS = "*" }
    Action    = "SNS:Publish"
    Resource  = aws_sns_topic.this.arn
    Condition = {
      Bool = { "aws:SecureTransport" = "false" }
    }
  }

  topic_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat([local.tls_deny_statement], tolist(var.config.additional_policy_statements))
  })
}

resource "aws_sns_topic" "this" {
  name       = var.config.name
  fifo_topic = var.config.fifo_topic

  # PCI DSS Req 3: encryption at rest. CMK when provided; otherwise null,
  # which the precondition only tolerates when allow_unencrypted = true.
  kms_master_key_id = var.config.kms_key_arn

  tags = local.tags

  # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
  lifecycle {
    precondition {
      condition     = var.config.kms_key_arn != null || var.config.allow_unencrypted
      error_message = "SNS topic has no kms_key_arn and config.allow_unencrypted is false. Provide a CMK ARN, or file a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Tightly-coupled sub-resource: a topic policy is meaningless without its topic.
resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = local.topic_policy
}
