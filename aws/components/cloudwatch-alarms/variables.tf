variable "config" {
  description = <<-EOT
    Configuration for the cloudwatch-alarms component: the CIS AWS Foundations /
    PCI DSS Req 10 monitoring & alerting baseline (Req 10.6 — alert on security
    events). It reads the CloudTrail->CloudWatch Logs group and, for each security
    event in the curated baseline, creates a log metric filter plus a metric alarm
    that notifies an SNS topic.

    All inputs live on this single object. PCI-compliant defaults are baked into
    the optional() fields: passing only the required `name_prefix` and
    `cloudtrail_log_group_name` provisions the FULL baseline alarm set, an
    encrypted SNS topic (with a dedicated CMK), and wires every alarm to it.

    This component composes atoms via module blocks ONLY:
    cloudwatch/cloudwatch-log-metric-filter (N), cloudwatch/cloudwatch-metric-alarm
    (N), and — unless a BYO `sns_topic_arn` is supplied — sns/sns-topic and
    kms/kms-key.
  EOT

  type = object({
    # --- Required: the caller must decide these. No defaults. ---
    # Base name for created resources (SNS topic, CMK alias, alarm/filter names).
    name_prefix = string
    # The CloudTrail -> CloudWatch Logs log group the metric filters read from.
    cloudtrail_log_group_name = string

    # BYO SNS topic ARN for alarm notifications. null = this component creates an
    # encrypted topic (PCI DSS Req 3/4) and a dedicated CMK (unless kms_key_arn set).
    sns_topic_arn = optional(string)

    # BYO CMK ARN for the created SNS topic. null + no sns_topic_arn = create one.
    kms_key_arn = optional(string)

    # Subset of baseline alarm keys to enable. null/empty = enable ALL baseline
    # alarms (the secure default — full CIS/PCI Req 10 monitoring coverage).
    enabled_alarms = optional(list(string))

    tags = optional(map(string), {})
  })

  # no `default` here because name_prefix and cloudtrail_log_group_name are required

  validation {
    condition     = length(var.config.name_prefix) > 0 && length(var.config.name_prefix) <= 64
    error_message = "config.name_prefix must be 1-64 characters."
  }

  validation {
    condition     = length(var.config.cloudtrail_log_group_name) > 0
    error_message = "config.cloudtrail_log_group_name must be a non-empty CloudWatch Logs group name."
  }

  validation {
    condition     = var.config.sns_topic_arn == null || can(regex("^arn:aws[a-zA-Z-]*:sns:", var.config.sns_topic_arn))
    error_message = "config.sns_topic_arn, when set, must be a valid SNS topic ARN (arn:aws:sns:...)."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  # Every requested alarm key must exist in the curated baseline (defined in
  # main.tf's local.baseline). The accepted keys are listed in the error message.
  validation {
    condition = var.config.enabled_alarms == null || alltrue([
      for k in var.config.enabled_alarms : contains([
        "unauthorized_api_calls",
        "console_signin_without_mfa",
        "root_account_usage",
        "iam_policy_changes",
        "cloudtrail_config_changes",
        "console_auth_failures",
        "disable_or_delete_cmk",
        "s3_bucket_policy_changes",
        "aws_config_changes",
        "security_group_changes",
        "nacl_changes",
        "network_gateway_changes",
        "route_table_changes",
        "vpc_changes",
        "organizations_changes",
      ], k)
    ])
    error_message = "config.enabled_alarms may only contain baseline keys: unauthorized_api_calls, console_signin_without_mfa, root_account_usage, iam_policy_changes, cloudtrail_config_changes, console_auth_failures, disable_or_delete_cmk, s3_bucket_policy_changes, aws_config_changes, security_group_changes, nacl_changes, network_gateway_changes, route_table_changes, vpc_changes, organizations_changes."
  }
}
