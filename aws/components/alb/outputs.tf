output "manifest" {
  description = "All outputs of the alb component, collected on a single object."
  value = {
    alb_arn      = module.alb.manifest.arn
    alb_dns_name = module.alb.manifest.dns_name
    alb_zone_id  = module.alb.manifest.zone_id

    security_group_id = module.security_group.manifest.id

    target_group_arns = [for tg in module.target_groups : tg.manifest.arn]
    listener_arns     = [for l in module.listeners : l.manifest.arn]

    # The S3 bucket name access logs are shipped to (created, BYO, or null when
    # logging is disabled).
    access_logs_bucket = local.effective_log_bucket
  }
}
