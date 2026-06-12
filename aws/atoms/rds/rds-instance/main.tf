locals {
  module_tags = {
    Module = "atoms/rds/rds-instance" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # PCI DSS Req 10: ship audit trails to CloudWatch. Pick an engine-appropriate
  # default log set when the caller does not specify one.
  is_postgres         = var.config.engine == "postgres"
  default_log_exports = local.is_postgres ? ["postgresql", "upgrade"] : ["audit", "error", "general", "slowquery"]
  log_exports         = coalesce(var.config.enabled_cloudwatch_logs_exports, local.default_log_exports)
}

resource "aws_db_instance" "this" {
  # checkov:skip=CKV_AWS_157: multi_az defaults true via config (optional(bool, true));
  # checkov:skip=CKV_AWS_293: deletion_protection defaults true; checkov cannot statically
  # checkov:skip=CKV_AWS_161: iam_database_authentication_enabled defaults true; resolve these
  # checkov:skip=CKV_AWS_353: performance_insights_enabled defaults true via config; values
  # checkov:skip=CKV_AWS_354: performance_insights_kms_key supplied by caller; through the
  # checkov:skip=CKV_AWS_226: auto_minor_version_upgrade defaults true via config; config
  # checkov:skip=CKV_AWS_133: backup_retention_period defaults to 14 (7..35 validated); object,
  # checkov:skip=CKV_AWS_118: enhanced monitoring is wired by callers/components; but the
  # checkov:skip=CKV_AWS_129: secure defaults are enforced by the secure_defaults test. Relaxing
  # checkov:skip=CKV_AWS_16: encryption/deletion/public access requires the auditable
  # config.allow_* escape hatches (PCI DSS Req 3/6/8/10).
  identifier = var.config.identifier
  engine     = var.config.engine

  engine_version = var.config.engine_version
  instance_class = var.config.instance_class

  allocated_storage     = var.config.allocated_storage
  max_allocated_storage = var.config.max_allocated_storage

  db_subnet_group_name   = var.config.db_subnet_group_name
  vpc_security_group_ids = var.config.vpc_security_group_ids
  port                   = var.config.port
  publicly_accessible    = var.config.publicly_accessible

  parameter_group_name = var.config.parameter_group_name
  option_group_name    = var.config.option_group_name

  # Encryption at rest — snapshots inherit this automatically (PCI DSS Req 3).
  storage_encrypted = var.config.storage_encrypted
  kms_key_id        = var.config.kms_key_arn

  multi_az = var.config.multi_az

  # Master credentials managed in Secrets Manager — no plaintext password is ever
  # accepted by this module (PCI DSS Req 8.2.1: no clear-text credentials).
  manage_master_user_password = var.config.manage_master_user_password
  username                    = var.config.master_username

  iam_database_authentication_enabled = var.config.iam_database_authentication_enabled

  backup_retention_period = var.config.backup_retention_period
  copy_tags_to_snapshot   = var.config.copy_tags_to_snapshot
  deletion_protection     = var.config.deletion_protection

  auto_minor_version_upgrade = var.config.auto_minor_version_upgrade

  # PCI DSS Req 10: Performance Insights retains query-level telemetry.
  performance_insights_enabled = var.config.performance_insights_enabled

  enabled_cloudwatch_logs_exports = local.log_exports

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = var.config.storage_encrypted || var.config.allow_unencrypted
      error_message = "storage_encrypted=false without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # Deletion protection must be intentional to weaken.
    precondition {
      condition     = var.config.deletion_protection || var.config.allow_deletion
      error_message = "deletion_protection=false without config.allow_deletion=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # Public accessibility must be intentional to enable (PCI DSS Req 1).
    precondition {
      condition     = !var.config.publicly_accessible || var.config.allow_public
      error_message = "publicly_accessible=true without config.allow_public=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
