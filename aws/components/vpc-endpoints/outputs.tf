output "manifest" {
  description = "All outputs of the vpc-endpoints component, collected on a single object."
  value = {
    security_group_id = module.endpoint_sg.manifest.id

    # Every endpoint id keyed by its short service name (gateway + interface).
    endpoint_ids = merge(
      { for k, m in module.gateway_endpoint : k => m.manifest.id },
      { for k, m in module.interface_endpoint : k => m.manifest.id },
    )

    gateway_endpoint_ids   = { for k, m in module.gateway_endpoint : k => m.manifest.id }
    interface_endpoint_ids = { for k, m in module.interface_endpoint : k => m.manifest.id }
  }
}
