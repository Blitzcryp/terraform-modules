output "manifest" {
  description = "All outputs of the sns component, collected on a single object."
  value = {
    topic_arn  = module.topic.manifest.arn
    topic_name = module.topic.manifest.name

    # created-or-BYO CMK ARN; encryption at rest is always on.
    kms_key_arn = local.kms_key_arn

    # Subscription ARNs, one per requested subscription (empty when none).
    subscription_arns = [for s in module.subscription : s.manifest.arn]
  }
}
