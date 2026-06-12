locals {
  module_tags = {
    Module = "atoms/cloudtrail/cloudtrail" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_cloudtrail" "this" {
  # checkov:skip=CKV_AWS_67: multi-region defaults to true via config.is_multi_region_trail
  # checkov:skip=CKV_AWS_251: logging defaults to true via config.enable_logging
  # checkov:skip=CKV_AWS_36: log file validation defaults to true via config.enable_log_file_validation
  # (disabling it requires the auditable config.allow_log_validation_disabled escape hatch).
  # checkov cannot statically resolve these optional(bool, true) values through the config object;
  # the secure defaults are enforced by the secure_defaults test (PCI DSS Req 10).
  # checkov:skip=CKV_AWS_252: SNS delivery notifications are an optional add-on, not a PCI-DSS
  # secure default for this atom; callers needing them wire an SNS topic at a higher layer.
  name           = var.config.name
  s3_bucket_name = var.config.s3_bucket_name
  s3_key_prefix  = var.config.s3_key_prefix

  is_multi_region_trail         = var.config.is_multi_region_trail
  enable_log_file_validation    = var.config.enable_log_file_validation
  include_global_service_events = var.config.include_global_service_events
  enable_logging                = var.config.enable_logging
  is_organization_trail         = var.config.is_organization_trail

  # Encrypt log files at rest with a CMK (PCI DSS Req 3). null only allowed via
  # the allow_unencrypted escape hatch (guarded by the precondition below).
  kms_key_id = var.config.kms_key_arn

  # Optional real-time delivery to CloudWatch Logs.
  cloud_watch_logs_group_arn = var.config.cloud_watch_logs_group_arn
  cloud_watch_logs_role_arn  = var.config.cloud_watch_logs_role_arn

  dynamic "event_selector" {
    for_each = var.config.event_selectors
    content {
      read_write_type           = try(event_selector.value.read_write_type, null)
      include_management_events = try(event_selector.value.include_management_events, null)

      dynamic "data_resource" {
        for_each = try(event_selector.value.data_resources, [])
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to disable (PCI DSS Req 3).
    precondition {
      condition     = var.config.kms_key_arn != null || var.config.allow_unencrypted
      error_message = "Trail encryption disabled without config.allow_unencrypted=true. Supply config.kms_key_arn, or file a PCI exception (security@emag.ro) and set the flag."
    }
    # Log file validation makes the trail tamper-evident (PCI DSS Req 10.5).
    precondition {
      condition     = var.config.enable_log_file_validation || var.config.allow_log_validation_disabled
      error_message = "Log file validation disabled without config.allow_log_validation_disabled=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
