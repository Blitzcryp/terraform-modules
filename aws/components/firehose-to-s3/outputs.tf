output "manifest" {
  description = "All outputs of the firehose-to-s3 component, collected on a single object."
  value = {
    firehose_arn  = module.firehose.manifest.arn
    firehose_name = module.firehose.manifest.name

    bucket_name = module.delivery_bucket.manifest.bucket
    bucket_arn  = module.delivery_bucket.manifest.arn

    role_arn = module.firehose_role.manifest.arn

    # Effective CMK everything is encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn

    log_group_name = module.log_group.manifest.name
  }
}
