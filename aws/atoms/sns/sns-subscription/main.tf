# NOTE: the aws_sns_topic_subscription resource does not support tags, so the
# config.tags field is accepted for interface parity with sibling atoms but is
# not applied to any resource here. Global tags come from provider default_tags.

# Exactly one logical resource for this atom: an SNS subscription. The topic it
# binds to is owned by a higher layer and passed in by reference.
resource "aws_sns_topic_subscription" "this" {
  topic_arn = var.config.topic_arn
  protocol  = var.config.protocol
  endpoint  = var.config.endpoint

  raw_message_delivery   = var.config.raw_message_delivery
  endpoint_auto_confirms = var.config.endpoint_auto_confirms
  filter_policy          = var.config.filter_policy
}
