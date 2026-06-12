output "manifest" {
  description = "All outputs of the cloudfront component, collected on a single object."
  value = {
    distribution_id  = module.distribution.manifest.id
    distribution_arn = module.distribution.manifest.arn
    domain_name      = module.distribution.manifest.domain_name
    hosted_zone_id   = module.distribution.manifest.hosted_zone_id

    # OAC id when fronting an S3 origin; null for custom origins.
    oac_id = local.create_oac ? module.oac[0].manifest.id : null

    # The owned access-log bucket NAME (null when logging is disabled or BYO).
    log_bucket = local.owned_log_bucket_name
  }
}
