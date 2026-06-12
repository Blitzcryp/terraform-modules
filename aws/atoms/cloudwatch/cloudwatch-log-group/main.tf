locals {
  module_tags = {
    Module = "atoms/cloudwatch/cloudwatch-log-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.config.name
  retention_in_days = var.config.retention_in_days
  kms_key_id        = var.config.kms_key_arn
  log_group_class   = var.config.log_group_class
  skip_destroy      = var.config.skip_destroy

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to disable (PCI DSS Req 3).
    precondition {
      condition     = var.config.kms_key_arn != null || var.config.allow_unencrypted
      error_message = "Log group has no KMS key (unencrypted at rest) without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # Defined log retention must be intentional to waive (PCI DSS Req 10.5/10.7).
    precondition {
      condition     = var.config.retention_in_days != 0 || var.config.allow_no_retention
      error_message = "config.retention_in_days=0 (logs never expire / no retention) without config.allow_no_retention=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
