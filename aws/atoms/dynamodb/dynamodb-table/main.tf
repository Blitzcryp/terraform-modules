locals {
  module_tags = {
    Module = "atoms/dynamodb/dynamodb-table" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # SSE with a customer-managed key is on whenever a CMK ARN is supplied.
  use_cmk = var.config.kms_key_arn != null

  pitr_enabled = var.config.enable_point_in_time_recovery
}

resource "aws_dynamodb_table" "this" {
  # checkov:skip=CKV_AWS_28: point_in_time_recovery.enabled defaults to true via
  # config.enable_point_in_time_recovery (optional(bool, true)) and is enforced by a
  # lifecycle precondition; disabling requires config.allow_no_pitr. Checkov cannot
  # statically resolve the value through the config object (false positive when
  # evaluated via a module call), but the secure default is enforced by the
  # secure_defaults test.
  name         = var.config.name
  billing_mode = var.config.billing_mode
  hash_key     = var.config.hash_key
  range_key    = var.config.range_key

  read_capacity  = var.config.billing_mode == "PROVISIONED" ? var.config.read_capacity : null
  write_capacity = var.config.billing_mode == "PROVISIONED" ? var.config.write_capacity : null

  stream_enabled   = var.config.stream_enabled
  stream_view_type = var.config.stream_enabled ? var.config.stream_view_type : null

  deletion_protection_enabled = var.config.deletion_protection_enabled

  dynamic "attribute" {
    for_each = var.config.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.config.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
      read_capacity      = lookup(global_secondary_index.value, "read_capacity", null)
      write_capacity     = lookup(global_secondary_index.value, "write_capacity", null)
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.config.local_secondary_indexes
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  dynamic "ttl" {
    for_each = var.config.ttl_attribute == null ? [] : [var.config.ttl_attribute]
    content {
      attribute_name = ttl.value
      enabled        = true
    }
  }

  # Encryption at rest with a customer-managed key (PCI DSS Req 3). When no CMK
  # is supplied (AWS-owned-key escape hatch), the block is omitted and DynamoDB
  # falls back to the AWS-owned key.
  dynamic "server_side_encryption" {
    for_each = local.use_cmk ? [1] : []
    content {
      enabled     = true
      kms_key_arn = var.config.kms_key_arn
    }
  }

  point_in_time_recovery {
    enabled = local.pitr_enabled
  }

  tags = local.tags

  lifecycle {
    # Encryption at rest with a CMK is required unless the AWS-owned-key hatch is flipped (PCI DSS Req 3).
    precondition {
      condition     = local.use_cmk || var.config.allow_aws_owned_key
      error_message = "DynamoDB table has no customer-managed KMS key. Supply config.kms_key_arn, or set config.allow_aws_owned_key=true to accept the AWS-owned key. File a PCI exception (security@emag.ro)."
    }

    # Point-in-time recovery must stay on unless explicitly waived.
    precondition {
      condition     = local.pitr_enabled || var.config.allow_no_pitr
      error_message = "Point-in-time recovery disabled without config.allow_no_pitr=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # Deletion protection must stay on unless explicitly waived.
    precondition {
      condition     = var.config.deletion_protection_enabled || var.config.allow_deletion
      error_message = "Deletion protection disabled without config.allow_deletion=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
