output "manifest" {
  description = "All outputs of the route53 component, collected on a single object."
  value = {
    zone_id      = module.zone.manifest.zone_id
    zone_arn     = module.zone.manifest.arn
    name_servers = module.zone.manifest.name_servers

    # null for private zones (query logging unsupported) — the log group is only
    # created for public zones.
    query_log_group_name = local.query_logging_enabled ? module.query_log_group[0].manifest.name : null
  }
}
