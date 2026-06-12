locals {
  module_tags = {
    Module = "atoms/backup/backup-plan" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_backup_plan" "this" {
  name = var.config.name

  dynamic "rule" {
    for_each = var.config.rules
    content {
      rule_name         = rule.value.rule_name
      target_vault_name = rule.value.target_vault_name
      schedule          = rule.value.schedule
      start_window      = rule.value.start_window
      completion_window = rule.value.completion_window

      # Retention lifecycle (PCI DSS Req 10.5.1). Rendered only when at least one
      # of cold_storage_after / delete_after is set.
      dynamic "lifecycle" {
        for_each = (rule.value.cold_storage_after != null || rule.value.delete_after != null) ? [1] : []
        content {
          cold_storage_after = rule.value.cold_storage_after
          delete_after       = rule.value.delete_after
        }
      }

      # Cross-region/cross-account copy for disaster recovery (optional).
      dynamic "copy_action" {
        for_each = rule.value.copy_action_destination_vault_arn != null ? [1] : []
        content {
          destination_vault_arn = rule.value.copy_action_destination_vault_arn

          dynamic "lifecycle" {
            for_each = (rule.value.cold_storage_after != null || rule.value.delete_after != null) ? [1] : []
            content {
              cold_storage_after = rule.value.cold_storage_after
              delete_after       = rule.value.delete_after
            }
          }
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = var.config.advanced_backup_settings
    content {
      backup_options = advanced_backup_setting.value.backup_options
      resource_type  = advanced_backup_setting.value.resource_type
    }
  }

  tags = local.tags
}
