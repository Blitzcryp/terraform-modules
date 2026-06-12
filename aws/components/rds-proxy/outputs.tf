output "manifest" {
  description = "All outputs of the rds-proxy component, collected on a single object."
  value = {
    proxy_arn         = module.proxy.manifest.arn
    proxy_name        = module.proxy.manifest.name
    proxy_endpoint    = module.proxy.manifest.endpoint
    security_group_id = module.security_group.manifest.id
    role_arn          = module.role.manifest.arn
  }
}
