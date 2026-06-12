locals {
  module_tags = {
    Module = "atoms/kinesis/kinesis-firehose-delivery-stream" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Server-side encryption is on by default with a CUSTOMER_MANAGED_CMK (PCI DSS
  # Req 3: protect stored data in transit through the buffer). The escape hatch
  # disables SSE entirely.
  sse_enabled = !var.config.allow_unencrypted

  # CloudWatch logging is enabled by default (PCI DSS Req 10) whenever a log
  # group is supplied; the stream still records delivery errors to it.
  cloudwatch_logging_enabled = var.config.cloudwatch_log_group_name != null
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  # checkov:skip=CKV_AWS_240: SSE defaults to enabled with a CUSTOMER_MANAGED_CMK;
  # checkov:skip=CKV_AWS_241: checkov cannot statically resolve enabled/key_type/
  # key_arn through the ternaries on var.config, but the secure default is
  # enforced by the secure_defaults test and the kms_key_arn validation. Relaxing
  # it requires config.allow_unencrypted=true (a grep-able PCI exception).
  name        = var.config.name
  destination = "extended_s3"

  # PCI DSS Req 3: encrypt the in-flight buffer with a customer-managed CMK.
  server_side_encryption {
    enabled  = local.sse_enabled
    key_type = local.sse_enabled ? "CUSTOMER_MANAGED_CMK" : "AWS_OWNED_CMK"
    key_arn  = local.sse_enabled ? var.config.kms_key_arn : null
  }

  extended_s3_configuration {
    role_arn   = var.config.role_arn
    bucket_arn = var.config.bucket_arn
    prefix     = var.config.prefix

    buffering_size     = var.config.buffering_size
    buffering_interval = var.config.buffering_interval

    # PCI DSS Req 3: encrypt delivered objects at rest with the CMK.
    kms_key_arn = var.config.kms_key_arn

    # PCI DSS Req 10: capture delivery errors in CloudWatch Logs.
    cloudwatch_logging_options {
      enabled         = local.cloudwatch_logging_enabled
      log_group_name  = var.config.cloudwatch_log_group_name
      log_stream_name = var.config.cloudwatch_log_stream_name
    }
  }

  tags = local.tags

  lifecycle {
    # Server-side encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = local.sse_enabled || var.config.allow_unencrypted
      error_message = "Server-side encryption disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
