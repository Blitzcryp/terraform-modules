locals {
  # Module-identity tag only; global tags come from provider default_tags.
  # NOTE: the AWS Config recorder/delivery-channel/status resources do not
  # accept tags. config.tags is kept for interface uniformity and surfaced in
  # the manifest, but cannot be applied to these resources.
  module_tags = {
    Module = "atoms/config/config-recorder"
  }
  tags = merge(local.module_tags, var.config.tags)
}

# Records configuration changes for resources in this account/region (PCI DSS
# Req 10). The IAM role and S3 bucket are taken as inputs (owned elsewhere).
resource "aws_config_configuration_recorder" "this" {
  name     = var.config.name
  role_arn = var.config.iam_role_arn

  recording_group {
    all_supported                 = var.config.record_all_resources
    include_global_resource_types = var.config.record_all_resources ? var.config.include_global_resource_types : false
  }
}

# Delivers configuration snapshots/history to the (pre-existing) S3 bucket.
# Must exist before the recorder can be started; the recorder must exist before
# the channel can be created.
resource "aws_config_delivery_channel" "this" {
  name           = var.config.name
  s3_bucket_name = var.config.s3_bucket_name
  sns_topic_arn  = var.config.sns_topic_arn

  depends_on = [aws_config_configuration_recorder.this]
}

# Starts the recorder. Requires the delivery channel to exist first.
resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
