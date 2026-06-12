output "manifest" {
  description = "All outputs of the waf component, collected on a single object."
  value = {
    web_acl_arn      = module.web_acl.manifest.arn
    web_acl_id       = module.web_acl.manifest.id
    web_acl_capacity = module.web_acl.manifest.capacity

    log_group_name = module.log_group.manifest.name

    # One association id per associate_resource_arns entry (empty list when none).
    association_ids = [for a in module.associations : a.manifest.id]
  }
}
