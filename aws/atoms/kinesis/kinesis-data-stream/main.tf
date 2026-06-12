locals {
  module_tags = {
    Module = "atoms/kinesis/kinesis-data-stream" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Encryption is KMS by default (PCI DSS Req 3: protect stored data). The escape
  # hatch flips encryption_type to NONE and clears the key reference.
  encryption_type = var.config.allow_unencrypted ? "NONE" : "KMS"

  # When encrypting, kms_key_id defaults to the AWS-managed key alias if the
  # caller did not bring their own CMK.
  kms_key_id = local.encryption_type == "KMS" ? coalesce(var.config.kms_key_arn, "alias/aws/kinesis") : null

  # shard_count only applies to PROVISIONED streams; ON_DEMAND must leave it null.
  shard_count = var.config.stream_mode == "PROVISIONED" ? var.config.shard_count : null
}

resource "aws_kinesis_stream" "this" {
  name             = var.config.name
  retention_period = var.config.retention_period
  shard_count      = local.shard_count

  encryption_type = local.encryption_type
  kms_key_id      = local.kms_key_id

  stream_mode_details {
    stream_mode = var.config.stream_mode
  }

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = local.encryption_type == "KMS" || var.config.allow_unencrypted
      error_message = "Encryption disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # PROVISIONED streams need a shard count; ON_DEMAND must not set one.
    precondition {
      condition     = var.config.stream_mode == "ON_DEMAND" ? var.config.shard_count == null : var.config.shard_count != null
      error_message = "config.shard_count is required for PROVISIONED streams and must be null for ON_DEMAND streams."
    }
  }
}
