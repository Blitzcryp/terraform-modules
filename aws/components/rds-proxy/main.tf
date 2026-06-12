locals {
  module_tags = {
    Module = "components/rds-proxy" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Proxy listens on the engine's default port; ingress is opened on it.
  proxy_port = var.config.engine_family == "POSTGRESQL" ? 5432 : (var.config.engine_family == "SQLSERVER" ? 1433 : 3306)

  # Proxy-port ingress rules: one per allowed app security group and one per CIDR.
  # No public (0.0.0.0/0) ingress is ever generated here (PCI DSS Req 1).
  sg_ingress_rules = [
    for sg in var.config.allowed_security_group_ids : {
      description                  = "Proxy-port ingress from app security group ${sg}"
      ip_protocol                  = "tcp"
      from_port                    = local.proxy_port
      to_port                      = local.proxy_port
      referenced_security_group_id = sg
    }
  ]
  cidr_ingress_rules = [
    for c in var.config.allowed_cidrs : {
      description = "Proxy-port ingress from CIDR ${c}"
      ip_protocol = "tcp"
      from_port   = local.proxy_port
      to_port     = local.proxy_port
      cidr_ipv4   = c
    }
  ]
  ingress_rules = concat(local.sg_ingress_rules, local.cidr_ingress_rules)

  # IAM trust policy: only the RDS service may assume the proxy role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  # Least-privilege inline policy (PCI DSS Req 7): the proxy may read ONLY the
  # supplied secret(s) and decrypt with KMS so Secrets Manager can return them.
  secrets_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadProxyDbSecrets"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.config.secret_arns
      },
      {
        Sid      = "DecryptProxyDbSecrets"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.*.amazonaws.com"
          }
        }
      }
    ]
  })
}

# --- Proxy security group (no public ingress; proxy port from supplied sources) -

module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name          = "${var.config.name}-proxy"
    vpc_id        = var.config.vpc_id
    description   = "Proxy-port access for the ${var.config.name} RDS proxy"
    ingress_rules = local.ingress_rules
    tags          = local.tags
  }
}

# --- IAM role the proxy assumes to read the DB credential secret(s) -----------

module "role" {
  source = "../../atoms/iam/iam-role"

  config = {
    name               = "${var.config.name}-proxy"
    description        = "Lets the ${var.config.name} RDS proxy read its DB credential secret(s)"
    assume_role_policy = local.assume_role_policy
    inline_policies = {
      read-db-secrets = local.secrets_policy
    }
    tags = local.tags
  }
}

# --- RDS Proxy (secure by default) --------------------------------------------

module "proxy" {
  source = "../../atoms/rds/rds-proxy"

  config = {
    name                   = var.config.name
    engine_family          = var.config.engine_family
    secret_arns            = var.config.secret_arns
    role_arn               = module.role.manifest.arn
    vpc_subnet_ids         = var.config.subnet_ids
    vpc_security_group_ids = [module.security_group.manifest.id]

    require_tls = var.config.require_tls

    target_db_instance_identifier = var.config.target_db_instance_identifier
    target_db_cluster_identifier  = var.config.target_db_cluster_identifier

    tags = local.tags

    # Forward escape hatch so an intentional, auditable relaxation is possible.
    allow_plaintext = var.config.allow_plaintext
  }
}
