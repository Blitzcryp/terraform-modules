output "manifest" {
  description = "All outputs of the private-encrypted-bucket component, collected on a single object."
  value = {
    bucket_id          = module.bucket.manifest.id
    bucket_arn         = module.bucket.manifest.arn
    bucket_name        = module.bucket.manifest.bucket
    bucket_domain_name = module.bucket.manifest.bucket_domain_name

    # KMS: created-or-BYO ARN; key_id is null when BYOK (we don't own the key).
    kms_key_arn = local.kms_key_arn
    kms_key_id  = local.create_kms_key ? module.kms_key[0].manifest.key_id : null

    # Companion log bucket name; null when logging disabled or an external
    # log bucket was supplied.
    log_bucket_name = local.create_log_bucket ? module.log_bucket[0].manifest.bucket : null
  }
}
