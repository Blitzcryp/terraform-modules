locals {
  module_tags = {
    Module = "atoms/rds/rds-proxy" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_db_proxy" "this" {
  name           = var.config.name
  engine_family  = var.config.engine_family
  role_arn       = var.config.role_arn
  vpc_subnet_ids = var.config.vpc_subnet_ids

  vpc_security_group_ids = var.config.vpc_security_group_ids

  # Encryption in transit between client and proxy (PCI DSS Req 4).
  require_tls = var.config.require_tls

  idle_client_timeout = var.config.idle_client_timeout
  debug_logging       = var.config.debug_logging

  # Authentication is delegated to Secrets Manager + IAM. We NEVER accept a
  # plaintext password — the proxy reads credentials from the referenced secret
  # and clients authenticate with IAM tokens (PCI DSS Req 8.2.1: no clear-text).
  dynamic "auth" {
    for_each = var.config.secret_arns
    content {
      auth_scheme = "SECRETS"
      iam_auth    = "REQUIRED"
      secret_arn  = auth.value
    }
  }

  tags = local.tags

  lifecycle {
    # TLS must be intentional to weaken (PCI DSS Req 4).
    precondition {
      condition     = var.config.require_tls || var.config.allow_plaintext
      error_message = "require_tls=false without config.allow_plaintext=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Default target group — tightly coupled to the proxy; meaningless on its own.
resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name
}

# Register the single backend target (DB instance or DB cluster).
resource "aws_db_proxy_target" "this" {
  db_proxy_name     = aws_db_proxy.this.name
  target_group_name = aws_db_proxy_default_target_group.this.name

  db_instance_identifier = var.config.target_db_instance_identifier
  db_cluster_identifier  = var.config.target_db_cluster_identifier
}
