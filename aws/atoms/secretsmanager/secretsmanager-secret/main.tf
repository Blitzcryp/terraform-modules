locals {
  module_tags = {
    Module = "atoms/secretsmanager/secretsmanager-secret" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  create_rotation = var.config.rotation_lambda_arn != null
  create_policy   = var.config.policy != null
}

# SECURITY: this resource defines only the secret container and its encryption,
# never the secret VALUE. Secret material is populated out-of-band by a secrets
# source or the rotation Lambda — never committed to source control
# (PCI DSS Req 3.5 protect stored credentials / Req 8 manage credentials).
resource "aws_secretsmanager_secret" "this" {
  name        = var.config.name
  description = var.config.description

  # PCI DSS Req 3: encrypt at rest with a customer-managed key. When null, AWS
  # uses the aws/secretsmanager managed key (gated by the escape hatch below).
  kms_key_id = var.config.kms_key_arn

  recovery_window_in_days = var.config.recovery_window_in_days

  tags = local.tags

  lifecycle {
    # Encryption with a CMK must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = var.config.kms_key_arn != null || var.config.allow_aws_managed_key
      error_message = "kms_key_arn is null without config.allow_aws_managed_key=true. The aws/secretsmanager managed key is less strict; supply a CMK ARN or file a PCI exception (security@emag.ro) and set the flag."
    }

    # Immediate (irreversible) deletion must be intentional.
    precondition {
      condition     = var.config.recovery_window_in_days != 0 || var.config.allow_immediate_deletion
      error_message = "recovery_window_in_days=0 (immediate deletion) without config.allow_immediate_deletion=true. Set the flag to confirm the secret can be force-deleted with no recovery window."
    }
  }
}

# Tightly-coupled rotation schedule — meaningless without the secret above.
resource "aws_secretsmanager_secret_rotation" "this" {
  # checkov:skip=CKV_AWS_304: rotation interval defaults to 30 days (config.rotation_days,
  # validated to 1..1000); the value flows from a module variable that checkov cannot
  # resolve statically, producing a false positive. 30 days is well within the 90-day limit.
  count = local.create_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.config.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.config.rotation_days
  }
}

# Tightly-coupled resource policy — meaningless without the secret above.
resource "aws_secretsmanager_secret_policy" "this" {
  count = local.create_policy ? 1 : 0

  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = var.config.policy
}
