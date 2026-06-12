output "manifest" {
  description = "All outputs of the network-acl component, collected on a single object."
  value = {
    network_acl_id  = module.network_acl.manifest.id
    network_acl_arn = module.network_acl.manifest.arn
  }
}
