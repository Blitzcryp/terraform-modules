output "manifest" {
  description = "All outputs of the cloudwatch-alarms component, collected on a single object."
  value = {
    # The SNS topic every alarm notifies (created here or BYO).
    sns_topic_arn = local.alarm_topic_arn

    # Effective CMK encrypting the created topic (created, BYO, or null when a BYO
    # topic was supplied so this component owns no encryption).
    kms_key_arn = local.create_topic ? local.effective_kms : null

    # Map of baseline event key -> created alarm ARN.
    alarm_arns = { for k, m in module.metric_alarm : k => m.manifest.arn }

    # Map of baseline event key -> created metric filter id.
    filter_ids = { for k, m in module.metric_filter : k => m.manifest.id }
  }
}
