data "aws_caller_identity" "current" {}

locals {
  # Whether this component owns the CMK. If the caller supplies a BYO key ARN we
  # skip creating a kms-key atom and encrypt recovery points with their key.
  create_kms        = var.config.kms_key_arn == null
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn

  vault_name     = "${var.config.name}-vault"
  plan_name      = "${var.config.name}-plan"
  selection_name = "${var.config.name}-selection"

  # ---------------------------------------------------------------------------
  # CRITICAL CORRECTNESS (apply-time): when this component creates the CMK, the
  # key policy must let the AWS Backup service principal (backup.amazonaws.com)
  # use the key, otherwise backup/copy/restore jobs fail with AccessDenied.
  # Grants: (a) account root full kms:* admin, and (b) backup.amazonaws.com the
  # encrypt/decrypt/datakey/createGrant actions. BYO keys are the caller's
  # responsibility to authorise.
  # ---------------------------------------------------------------------------
  backup_service_principal = "backup.amazonaws.com"

  kms_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowAWSBackup"
        Effect    = "Allow"
        Principal = { Service = local.backup_service_principal }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      },
    ]
  })

  # Trust policy for the AWS Backup service role (PCI DSS Req 8: identify the
  # principal allowed to assume the role).
  backup_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAWSBackupAssume"
        Effect    = "Allow"
        Principal = { Service = local.backup_service_principal }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # AWS-managed policies for backup and restore operations. These are the
  # purpose-built least-privilege managed policies AWS publishes for the service
  # role; using them avoids hand-rolling broad backup permissions (PCI Req 7).
  backup_managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
  ]

  # Convert the selection_tags map to STRINGEQUALS selection-tag objects.
  selection_tag_objects = [
    for k, v in var.config.selection_tags : {
      type  = "STRINGEQUALS"
      key   = k
      value = v
    }
  ]
}

# --- KMS CMK (created only when no BYO key is supplied) -----------------------
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "Backup CMK for ${var.config.name} (PCI DSS Req 3/9/10)"
    alias       = "${var.config.name}/backup"
    # Secure defaults inherited from the atom: rotation on, 30-day deletion
    # window, symmetric ENCRYPT_DECRYPT. We override only the policy so the AWS
    # Backup service can use the key (see local.kms_policy).
    policy = local.kms_policy
    tags   = var.config.tags
  }
}

# --- Encrypted backup vault (+ optional WORM Vault Lock) ----------------------
module "vault" {
  source = "../../atoms/backup/backup-vault"

  config = {
    name        = local.vault_name
    kms_key_arn = local.effective_kms_arn # never null -> always encrypted

    enable_lock        = var.config.enable_vault_lock
    lock_mode          = var.config.lock_mode
    min_retention_days = var.config.min_retention_days
    max_retention_days = var.config.max_retention_days

    tags = var.config.tags
  }
}

# --- Scheduled backup plan (single rule from schedule/windows/lifecycle) ------
module "plan" {
  source = "../../atoms/backup/backup-plan"

  config = {
    name = local.plan_name
    rules = [
      {
        rule_name          = "daily"
        target_vault_name  = module.vault.manifest.name
        schedule           = var.config.schedule
        start_window       = var.config.start_window
        completion_window  = var.config.completion_window
        cold_storage_after = var.config.cold_storage_after_days
        delete_after       = var.config.delete_after_days
      }
    ]
    tags = var.config.tags
  }
}

# --- AWS Backup service role (trusts backup.amazonaws.com) --------------------
module "backup_role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name                = "${var.config.name}-backup-role"
    description         = "AWS Backup service role for ${var.config.name} (PCI DSS Req 7)"
    assume_role_policy  = local.backup_assume_role_policy
    managed_policy_arns = local.backup_managed_policy_arns
    tags                = var.config.tags
  }
}

# --- Tag-based + ARN-based resource selection ---------------------------------
module "selection" {
  source = "../../atoms/backup/backup-selection"

  config = {
    name           = local.selection_name
    plan_id        = module.plan.manifest.id
    iam_role_arn   = module.backup_role.manifest.arn
    resources      = var.config.resource_arns
    selection_tags = local.selection_tag_objects
    tags           = var.config.tags
  }
}
