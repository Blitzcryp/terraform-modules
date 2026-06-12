output "manifest" {
  description = "All outputs of the findings-notification component, collected on a single object."
  value = {
    # The EventBridge rule routing findings.
    rule_arn = module.rule.manifest.arn

    # The encrypted SNS topic findings are published to.
    topic_arn = module.topic.manifest.arn

    # Effective CMK encrypting the topic (created or BYO); encryption is always on.
    kms_key_arn = local.kms_key_arn

    # The id of the rule->topic target.
    target_id = module.target.manifest.target_id
  }
}
