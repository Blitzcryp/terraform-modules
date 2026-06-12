data "aws_caller_identity" "current" {}

locals {
  module_tags = {
    Module = "atoms/kms/kms-key" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Least-privilege default policy: only the account root may administer the key.
  # Grants/usage are delegated explicitly to principals by the caller via custom policy.
  default_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_key" "this" {
  description              = var.config.description
  deletion_window_in_days  = var.config.deletion_window_in_days
  enable_key_rotation      = var.config.enable_key_rotation
  multi_region             = var.config.multi_region
  key_usage                = var.config.key_usage
  customer_master_key_spec = var.config.key_spec
  policy                   = coalesce(var.config.policy, local.default_policy)

  tags = local.tags

  # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
  lifecycle {
    precondition {
      condition     = var.config.enable_key_rotation || var.config.allow_rotation_disabled
      error_message = "Key rotation disabled without config.allow_rotation_disabled=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

resource "aws_kms_alias" "this" {
  count         = var.config.alias == null ? 0 : 1
  name          = "alias/${var.config.alias}"
  target_key_id = aws_kms_key.this.key_id
}
