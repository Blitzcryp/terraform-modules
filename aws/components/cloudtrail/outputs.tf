output "manifest" {
  description = "All outputs of the cloudtrail component, collected on a single object."
  value = {
    trail_arn = module.trail.manifest.arn
    trail_id  = module.trail.manifest.id

    bucket_name = module.log_bucket.manifest.bucket

    # Effective CMK the trail + log group are encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn

    log_group_name      = module.log_group.manifest.name
    cloudwatch_role_arn = module.cloudwatch_role.manifest.arn
  }
}
