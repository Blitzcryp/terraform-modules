output "manifest" {
  description = "All outputs of the sqs component, collected on a single object."
  value = {
    queue_arn  = module.queue.manifest.arn
    queue_url  = module.queue.manifest.url
    queue_name = module.queue.manifest.name

    # DLQ ARN; null when config.enable_dlq = false.
    dlq_arn = module.queue.manifest.dlq_arn

    # created-or-BYO CMK ARN; encryption at rest is always on with a CMK.
    kms_key_arn = local.kms_key_arn
  }
}
