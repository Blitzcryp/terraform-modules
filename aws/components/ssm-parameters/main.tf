locals {
  # Create a dedicated CMK only when the caller did not bring their own.
  create_kms_key = var.config.kms_key_arn == null

  # Resolve the KMS key ARN that encrypts every parameter: the created atom's
  # key, or the caller-supplied BYOK ARN.
  kms_key_arn = local.create_kms_key ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
}

# --- KMS key atom (the CMK that encrypts every parameter). Owned by this
# component, created only when no BYOK key is supplied. ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms_key ? 1 : 0

  config = {
    description = "CMK for SSM parameters ${var.config.name_prefix} (ssm-parameters)"
    alias       = "ssm/${var.config.name_prefix}"
    tags        = var.config.tags
  }
}

# --- One SSM parameter atom per entry in the parameters map. Each is a
# SecureString encrypted with the created-or-BYO CMK; values are supplied
# out-of-band, never committed (PCI DSS Req 3 / Req 8). ---
module "parameter" {
  source = "../../atoms/ssm/ssm-parameter"
  # Iterate over the (non-secret) parameter keys. The map itself is sensitive
  # because it carries values, so for_each is keyed by the nonsensitive names and
  # each entry is looked up by key.
  for_each = toset(nonsensitive(keys(var.config.parameters)))

  config = {
    name        = "${var.config.name_prefix}/${each.key}"
    value       = var.config.parameters[each.key].value # SECURITY: supplied out-of-band (PCI DSS Req 3 / Req 8)
    type        = "SecureString"
    kms_key_arn = local.kms_key_arn
    description = var.config.parameters[each.key].description
    tier        = var.config.parameters[each.key].tier

    tags = var.config.tags
  }
}
