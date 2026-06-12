output "manifest" {
  description = "All outputs of the opensearch component, collected on a single object."
  value = {
    domain_arn        = module.domain.manifest.arn
    domain_name       = module.domain.manifest.domain_name
    domain_id         = module.domain.manifest.domain_id
    endpoint          = module.domain.manifest.endpoint
    security_group_id = module.security_group.manifest.id
    kms_key_arn       = local.effective_kms_arn
    log_group_name    = module.log_group.manifest.name
  }
}
