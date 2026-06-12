locals {
  module_tags = {
    Module = "blueprints/fargate-web-service" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # --- Conditional / enable logic -------------------------------------------
  has_domain      = var.config.domain_name != null
  db_enabled      = var.config.enable_database
  db_serverless   = var.config.database.serverless
  cache_enabled   = var.config.enable_cache
  secrets_enabled = var.config.enable_secrets
  ecr_enabled     = var.config.enable_ecr
  waf_enabled     = var.config.enable_waf

  # --- Network resolution (BYO or created) ----------------------------------
  # When create_network is true the secure-network component is composed and we
  # read its manifest; otherwise we use the caller-supplied ids. The blueprint
  # downstream always reads these three locals so the source is transparent.
  vpc_id = var.config.create_network ? module.network[0].manifest.vpc_id : var.config.vpc_id

  public_subnet_ids = var.config.create_network ? [
    for s in var.config.subnets : module.network[0].manifest.subnet_ids_by_name[s.name] if s.public
  ] : var.config.public_subnet_ids

  private_subnet_ids = var.config.create_network ? [
    for s in var.config.subnets : module.network[0].manifest.subnet_ids_by_name[s.name] if !s.public
  ] : var.config.private_subnet_ids

  # --- TLS / listeners -------------------------------------------------------
  # The ALB always terminates TLS (PCI DSS Req 4). The effective cert is either
  # the ACM-issued cert (when a domain is set) or the caller's BYO cert. The
  # blueprint config validation guarantees exactly one source is present, so the
  # ALB always uses its secure default listener set (HTTPS:443 + HTTP->HTTPS
  # redirect) and default HTTPS target group with this certificate.
  certificate_arn = local.has_domain ? module.certificate[0].manifest.certificate_arn : var.config.certificate_arn

  # --- App container definitions --------------------------------------------
  # Assembled JSON for the single app container. Logs ship to the audit-logging
  # group via awslogs. SECURITY: only NON-SECRET env vars go in `environment`;
  # secret material must be injected via a `secrets` block referencing the
  # secrets-manager / RDS master-user secret ARNs (PCI DSS Req 3 / Req 8).
  container_definitions = jsonencode([
    {
      name      = var.config.container_name
      image     = var.config.container_image
      essential = true
      # Read-only root filesystem hardens the container (PCI DSS Req 2 / Req 6).
      readonlyRootFilesystem = true
      portMappings = [
        { containerPort = var.config.container_port, protocol = "tcp" }
      ]
      environment = [for k, v in var.config.environment : { name = k, value = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = module.audit_logging.manifest.log_group_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.config.container_name
        }
      }
    }
  ])

  alb_dns_name = module.alb.manifest.alb_dns_name
  url          = local.has_domain ? "https://${var.config.domain_name}" : "http://${local.alb_dns_name}"
}

data "aws_region" "current" {}

# --- 1. Network (optional create) -------------------------------------------
module "network" {
  source = "../../components/secure-network"
  count  = var.config.create_network ? 1 : 0

  config = {
    name       = var.config.name_prefix
    cidr_block = var.config.vpc_cidr
    subnets    = var.config.subnets
    tags       = local.tags
  }
}

# --- 2. Audit logging (always): app log group + CMK -------------------------
module "audit_logging" {
  source = "../../components/audit-logging"

  config = {
    name_prefix = "${var.config.name_prefix}-app"
    tags        = local.tags
  }
}

# --- 3. ECS cluster (always) -------------------------------------------------
module "ecs_cluster" {
  source = "../../components/ecs-cluster"

  config = {
    name = var.config.name_prefix
    tags = local.tags
  }
}

# --- 4. ECR repository (optional) -------------------------------------------
module "ecr" {
  source = "../../components/ecr"
  count  = local.ecr_enabled ? 1 : 0

  config = {
    name = var.config.name_prefix
    tags = local.tags
  }
}

# --- 5. ACM certificate (only with a domain) --------------------------------
module "certificate" {
  source = "../../components/acm"
  count  = local.has_domain ? 1 : 0

  config = {
    domain_name    = var.config.domain_name
    hosted_zone_id = var.config.hosted_zone_id
    tags           = local.tags
  }
}

# --- 6. ALB (always) — the intentional public entrypoint --------------------
# A web service must be reachable from the internet, so the ALB is deliberately
# internet-facing (internal=false + allow_internet_facing) with public :443/:80
# ingress (allow_public_ingress). This is the single documented public surface;
# WAF (when enabled) sits in front of it and the app tasks stay private.
module "alb" {
  source = "../../components/alb"

  config = {
    name       = var.config.name_prefix
    vpc_id     = local.vpc_id
    subnet_ids = local.public_subnet_ids

    # ESCAPE HATCHES (documented): a public web service needs a public ALB.
    internal              = false
    allow_internet_facing = true
    ingress_cidrs         = ["0.0.0.0/0"]
    allow_public_ingress  = true

    # TLS-terminating edge: the ACM-issued or BYO certificate feeds the secure
    # default listener set (HTTPS:443 forward + HTTP:80 -> HTTPS redirect). TLS is
    # terminated at the ALB; the backend leg to the task (inside the private VPC)
    # is HTTP on the container port, so we author a matching target group rather
    # than the component's HTTPS:443 default (whose health check would fail).
    certificate_arn = local.certificate_arn
    target_groups = [{
      name     = substr("${var.config.name_prefix}-tg", 0, 32)
      port     = var.config.container_port
      protocol = "HTTP"
      health_check = {
        protocol = "HTTP"
        port     = "traffic-port"
        path     = "/"
      }
    }]

    tags = local.tags
  }
}

# --- 7. WAF (optional) — associated to the ALB ------------------------------
module "waf" {
  source = "../../components/waf"
  count  = local.waf_enabled ? 1 : 0

  config = {
    name                    = var.config.name_prefix
    scope                   = "REGIONAL"
    associate_resource_arns = [module.alb.manifest.alb_arn]
    tags                    = local.tags
  }
}

# --- 8. ECS service (always) — app in PRIVATE subnets, no public IP ---------
# Wired to the ALB target group; ingress to the service SG comes only from the
# ALB security group on the container port (PCI DSS Req 1).
module "ecs_service" {
  source = "../../components/ecs-service"

  config = {
    name        = var.config.name_prefix
    cluster_arn = module.ecs_cluster.manifest.cluster_arn
    vpc_id      = local.vpc_id
    subnet_ids  = local.private_subnet_ids

    container_definitions = local.container_definitions
    cpu                   = var.config.cpu
    memory                = var.config.memory
    desired_count         = var.config.desired_count
    execution_role_arn    = var.config.execution_role_arn
    task_role_arn         = var.config.task_role_arn

    kms_key_arn = module.audit_logging.manifest.kms_key_arn

    # Private networking (no public IP) — the secure default; no escape hatch.
    target_group_arn = module.alb.manifest.target_group_arns[0]
    container_name   = var.config.container_name
    container_port   = var.config.container_port

    # Only the ALB SG may reach the app on the container port.
    ingress_rules = [{
      description                  = "App traffic from the ALB"
      ip_protocol                  = "tcp"
      from_port                    = var.config.container_port
      to_port                      = var.config.container_port
      referenced_security_group_id = module.alb.manifest.security_group_id
    }]

    tags = local.tags
  }
}

# --- 9a. Aurora (provisioned) — private; only the app SG may connect --------
module "database" {
  source = "../../components/rds-aurora"
  count  = local.db_enabled && !local.db_serverless ? 1 : 0

  config = {
    name       = var.config.name_prefix
    vpc_id     = local.vpc_id
    subnet_ids = local.private_subnet_ids

    engine                     = var.config.database.engine
    instance_count             = var.config.database.instance_count
    instance_class             = var.config.database.instance_class
    allowed_security_group_ids = [module.ecs_service.manifest.security_group_id]

    tags = local.tags
  }
}

# --- 9b. Aurora Serverless v2 — private; only the app SG may connect --------
module "database_serverless" {
  source = "../../components/rds-aurora-serverless"
  count  = local.db_enabled && local.db_serverless ? 1 : 0

  config = {
    name       = var.config.name_prefix
    vpc_id     = local.vpc_id
    subnet_ids = local.private_subnet_ids

    engine                     = var.config.database.engine
    instance_count             = var.config.database.instance_count
    min_capacity               = var.config.database.min_capacity
    max_capacity               = var.config.database.max_capacity
    allowed_security_group_ids = [module.ecs_service.manifest.security_group_id]

    tags = local.tags
  }
}

# --- 10. ElastiCache (optional) — private; only the app SG may connect ------
module "cache" {
  source = "../../components/elasticache"
  count  = local.cache_enabled ? 1 : 0

  config = {
    name       = var.config.name_prefix
    vpc_id     = local.vpc_id
    subnet_ids = local.private_subnet_ids

    node_type                  = var.config.cache.node_type
    num_cache_clusters         = var.config.cache.num_cache_clusters
    allowed_security_group_ids = [module.ecs_service.manifest.security_group_id]

    tags = local.tags
  }
}

# --- 11. Secrets Manager (optional) — app secrets vault ---------------------
module "secrets" {
  source = "../../components/secrets-manager"
  count  = local.secrets_enabled ? 1 : 0

  config = {
    name_prefix = var.config.name_prefix
    secrets     = var.config.secrets
    tags        = local.tags
  }
}

# --- 12. DNS alias record (only with a domain) ------------------------------
# Apex/subdomain alias A record pointing at the (public) ALB.
module "dns_record" {
  source = "../../components/dns-record"
  count  = local.has_domain ? 1 : 0

  config = {
    zone_id = var.config.hosted_zone_id
    records = [{
      name = var.config.domain_name
      type = "A"
      alias = {
        name                   = module.alb.manifest.alb_dns_name
        zone_id                = module.alb.manifest.alb_zone_id
        evaluate_target_health = true
      }
    }]
    tags = local.tags
  }
}
