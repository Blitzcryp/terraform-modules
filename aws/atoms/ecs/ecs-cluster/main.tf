locals {
  module_tags = {
    Module = "atoms/ecs/ecs-cluster" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # ECS Exec audit logging to CloudWatch is only wired up when both a CMK and a
  # log group are supplied; sessions are then encrypted (PCI DSS Req 10 / Req 3).
  exec_logging_enabled = var.config.kms_key_arn != null && var.config.execute_command_log_group_name != null
}

resource "aws_ecs_cluster" "this" {
  name = var.config.name

  # Container Insights drives the monitoring telemetry PCI DSS Req 10 expects.
  # Two mutually-exclusive blocks so the secure path emits a literal "enabled"
  # that static scanners (CKV_AWS_65) can verify; the disabled path is only
  # reachable via the audited allow_container_insights_disabled escape hatch.
  dynamic "setting" {
    for_each = var.config.enable_container_insights ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }
  dynamic "setting" {
    for_each = var.config.enable_container_insights ? [] : [1]
    content {
      name = "containerInsights"
      # checkov:skip=CKV_AWS_65: Container Insights intentionally disabled via the
      # audited config.allow_container_insights_disabled escape hatch (PCI exception, security@emag.ro).
      value = "disabled"
    }
  }

  configuration {
    execute_command_configuration {
      # When a CMK is provided, ECS Exec session data is encrypted with it.
      kms_key_id = var.config.kms_key_arn

      # Log every ECS Exec session to an encrypted CloudWatch group for audit.
      logging = local.exec_logging_enabled ? "OVERRIDE" : "DEFAULT"

      dynamic "log_configuration" {
        for_each = local.exec_logging_enabled ? [1] : []
        content {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = var.config.execute_command_log_group_name
        }
      }
    }
  }

  tags = local.tags

  # Monitoring must be intentional to weaken (PCI DSS Req 10: track & monitor access).
  lifecycle {
    precondition {
      condition     = var.config.enable_container_insights || var.config.allow_container_insights_disabled
      error_message = "Container Insights disabled without config.allow_container_insights_disabled=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Tightly-coupled sub-resource: capacity providers are meaningless without the cluster.
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.config.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.config.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      base              = default_capacity_provider_strategy.value.base
      weight            = default_capacity_provider_strategy.value.weight
    }
  }
}
