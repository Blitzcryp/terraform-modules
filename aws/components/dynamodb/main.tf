locals {
  # Create a dedicated CMK only when the caller did not bring their own.
  create_kms_key = var.config.kms_key_arn == null

  # Resolve the KMS key ARN that encrypts the table: the created atom's key, or
  # the caller-supplied BYOK ARN.
  kms_key_arn = local.create_kms_key ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
}

# --- KMS key atom (the CMK that encrypts the table). Owned by this component,
# created only when no BYOK key is supplied. ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms_key ? 1 : 0

  config = {
    description = "CMK for DynamoDB table ${var.config.name} (dynamodb)"
    alias       = "dynamodb/${var.config.name}"
    tags        = var.config.tags
  }
}

# --- DynamoDB table atom: CMK SSE, point-in-time recovery on, deletion
# protection on (all secure defaults of the atom). ---
module "table" {
  source = "../../atoms/dynamodb/dynamodb-table"

  config = {
    name       = var.config.name
    hash_key   = var.config.hash_key
    range_key  = var.config.range_key
    attributes = var.config.attributes

    billing_mode             = var.config.billing_mode
    global_secondary_indexes = var.config.global_secondary_indexes
    ttl_attribute            = var.config.ttl_attribute
    stream_enabled           = var.config.stream_enabled
    stream_view_type         = var.config.stream_view_type

    kms_key_arn = local.kms_key_arn

    tags = var.config.tags
  }
}
