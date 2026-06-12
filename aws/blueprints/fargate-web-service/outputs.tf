output "manifest" {
  description = "All outputs of the fargate-web-service blueprint, collected on a single object."
  value = {
    service_name = module.ecs_service.manifest.service_name
    cluster_arn  = module.ecs_cluster.manifest.cluster_arn

    alb_arn      = module.alb.manifest.alb_arn
    alb_dns_name = module.alb.manifest.alb_dns_name
    # https://<domain> when a custom domain is set, else http://<alb-dns-name>.
    url = local.url

    # ECR repository URL, or null when the ECR tier is disabled.
    ecr_repository_url = local.ecr_enabled ? module.ecr[0].manifest.repository_url : null

    # DB writer endpoint, or null when the database tier is disabled. Selects
    # whichever Aurora flavour (provisioned / serverless) was composed.
    database_endpoint = (
      local.db_enabled ?
      (local.db_serverless ? module.database_serverless[0].manifest.endpoint : module.database[0].manifest.endpoint)
      : null
    )

    # The RDS master-user secret ARN (managed in Secrets Manager); null when no
    # database. Reference this from the container `secrets` block to inject DB
    # credentials without plaintext (PCI DSS Req 3 / Req 8).
    database_master_secret_arn = (
      local.db_enabled ?
      (local.db_serverless ? module.database_serverless[0].manifest.master_user_secret_arn : module.database[0].manifest.master_user_secret_arn)
      : null
    )

    # Cache primary endpoint, or null when the cache tier is disabled.
    cache_endpoint = local.cache_enabled ? module.cache[0].manifest.primary_endpoint : null

    # WAF Web ACL ARN, or null when the WAF tier is disabled.
    waf_web_acl_arn = local.waf_enabled ? module.waf[0].manifest.web_acl_arn : null

    # ACM certificate ARN, or null when no custom domain.
    certificate_arn = local.certificate_arn

    # Map of app secret ARNs (logical name => ARN); null when secrets disabled.
    app_secret_arns = local.secrets_enabled ? module.secrets[0].manifest.secret_arns : null

    log_group_name = module.audit_logging.manifest.log_group_name
    vpc_id         = local.vpc_id
  }
}
