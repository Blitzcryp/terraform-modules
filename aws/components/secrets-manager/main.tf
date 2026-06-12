locals {
  # Create a dedicated CMK only when the caller did not bring their own.
  create_kms_key = var.config.kms_key_arn == null

  # Resolve the KMS key ARN that encrypts every secret: the created atom's key,
  # or the caller-supplied BYOK ARN.
  kms_key_arn = local.create_kms_key ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
}

# --- KMS key atom (the CMK that encrypts the vault's secrets). Owned by this
# component, created only when no BYOK key is supplied. ---
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms_key ? 1 : 0

  config = {
    description = "CMK for Secrets Manager vault ${var.config.name_prefix} (secrets-manager)"
    alias       = "secretsmanager/${var.config.name_prefix}"
    tags        = var.config.tags
  }
}

# --- One secret atom per entry in the secrets map. Each is encrypted with the
# created-or-BYO CMK; values are populated out-of-band (PCI DSS Req 3.5 / 8). ---
module "secret" {
  source   = "../../atoms/secretsmanager/secretsmanager-secret"
  for_each = var.config.secrets

  config = {
    name        = "${var.config.name_prefix}/${each.key}"
    description = each.value.description
    kms_key_arn = local.kms_key_arn

    recovery_window_in_days = var.config.recovery_window_in_days

    rotation_lambda_arn = each.value.rotation_lambda_arn
    rotation_days       = each.value.rotation_days
    policy              = each.value.policy

    tags = var.config.tags
  }
}
