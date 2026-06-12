locals {
  module_tags = {
    Module = "atoms/backup/backup-vault" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Compliance mode is selected by passing changeable_for_days to the lock
  # configuration; governance mode omits it. This mirrors the AWS Backup Vault
  # Lock API where the cooling-off period is what makes the lock immutable.
  compliance_lock = var.config.enable_lock && var.config.lock_mode == "compliance"
}

resource "aws_backup_vault" "this" {
  name        = var.config.name
  kms_key_arn = var.config.kms_key_arn

  tags = local.tags

  # Encryption at rest with a customer-managed key must be intentional to weaken
  # (PCI DSS Req 3). A null kms_key_arn lets AWS Backup use an AWS-managed key,
  # which is only allowed when the caller flips the escape hatch.
  lifecycle {
    precondition {
      condition     = var.config.kms_key_arn != null || var.config.allow_unencrypted
      error_message = "Vault has no customer-managed kms_key_arn and config.allow_unencrypted is not true. AWS Backup would use an AWS-managed key. File a PCI exception (security@emag.ro) and set the flag, or supply config.kms_key_arn."
    }
  }
}

# Tightly-coupled Vault Lock (WORM immutability) — meaningless without the vault.
# Rendered only when enable_lock = true. In compliance mode the lock becomes
# permanently immutable once changeable_for_days elapses (PCI DSS Req 10.5 / 12).
resource "aws_backup_vault_lock_configuration" "this" {
  count = var.config.enable_lock ? 1 : 0

  backup_vault_name   = aws_backup_vault.this.name
  min_retention_days  = var.config.min_retention_days
  max_retention_days  = var.config.max_retention_days
  changeable_for_days = local.compliance_lock ? var.config.changeable_for_days : null
}
