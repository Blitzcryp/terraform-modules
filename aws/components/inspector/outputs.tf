output "manifest" {
  description = "All outputs of the inspector component, collected on a single object."
  value = {
    inspector_id   = module.inspector.manifest.id
    resource_types = module.inspector.manifest.resource_types

    # The findings-notification topic. A future EventBridge rule must subscribe
    # Inspector findings to this ARN. null when create_notification_topic=false.
    notification_topic_arn = local.create_topic ? module.notification_topic[0].manifest.arn : null

    # The effective CMK encrypting the topic (created or BYO); null when no topic.
    kms_key_arn = local.effective_kms_arn
  }
}
