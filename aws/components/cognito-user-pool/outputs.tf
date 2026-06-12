output "manifest" {
  description = "All outputs of the hardened Cognito user pool component, collected on a single object. client_secret is sensitive."
  sensitive   = true # client_secret taints the whole object as sensitive
  value = {
    user_pool_id  = module.user_pool.manifest.id
    user_pool_arn = module.user_pool.manifest.arn
    endpoint      = module.user_pool.manifest.endpoint
    client_id     = module.user_pool_client.manifest.client_id
    client_secret = module.user_pool_client.manifest.client_secret
    domain        = var.config.domain == null ? null : module.user_pool_domain[0].manifest.domain
  }
}
