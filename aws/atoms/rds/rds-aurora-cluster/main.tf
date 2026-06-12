locals {
  module_tags = {
    Module = "atoms/rds/rds-aurora-cluster" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  is_mysql = var.config.engine == "aurora-mysql"

  # PCI DSS Req 10: ship audit trails to CloudWatch. Pick an engine-appropriate
  # default log set when the caller does not specify one.
  default_log_exports = local.is_mysql ? ["audit", "error", "general", "slowquery"] : ["postgresql"]
  log_exports         = coalesce(var.config.enabled_cloudwatch_logs_exports, local.default_log_exports)

  # Serverless v2 forces instances onto the db.serverless class.
  is_serverless  = var.config.serverlessv2_scaling_configuration != null
  instance_class = local.is_serverless ? "db.serverless" : var.config.instance_class
}

resource "aws_rds_cluster" "this" {
  # checkov:skip=CKV_AWS_96: storage_encrypted defaults true via config (optional(bool, true));
  # checkov:skip=CKV_AWS_162: iam_database_authentication_enabled defaults true; checkov cannot
  # checkov:skip=CKV_AWS_133: statically resolve these values through the config object, but the
  # checkov:skip=CKV_AWS_139: secure defaults are enforced by the secure_defaults test. Relaxing
  # checkov:skip=CKV_AWS_313: encryption/deletion-protection requires the auditable
  # config.allow_unencrypted / config.allow_deletion escape hatches (PCI DSS Req 3/8/10).
  cluster_identifier = var.config.cluster_identifier
  engine             = var.config.engine
  engine_mode        = var.config.engine_mode

  db_subnet_group_name   = var.config.db_subnet_group_name
  vpc_security_group_ids = var.config.vpc_security_group_ids

  # Encryption at rest — snapshots inherit this automatically (PCI DSS Req 3).
  storage_encrypted = var.config.storage_encrypted
  kms_key_id        = var.config.kms_key_arn

  # Master credentials managed in Secrets Manager — no plaintext password is ever
  # accepted by this module (PCI DSS Req 8.2.1: no clear-text credentials).
  manage_master_user_password   = var.config.manage_master_user_password
  master_username               = var.config.master_username
  master_user_secret_kms_key_id = var.config.master_user_secret_kms_key_id

  iam_database_authentication_enabled = var.config.iam_database_authentication_enabled

  backup_retention_period = var.config.backup_retention_period
  copy_tags_to_snapshot   = var.config.copy_tags_to_snapshot
  deletion_protection     = var.config.deletion_protection

  enabled_cloudwatch_logs_exports = local.log_exports

  preferred_backup_window      = var.config.preferred_backup_window
  preferred_maintenance_window = var.config.preferred_maintenance_window

  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.is_serverless ? [var.config.serverlessv2_scaling_configuration] : []
    content {
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
    }
  }

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
  }
}

resource "aws_rds_cluster_instance" "this" {
  # checkov:skip=CKV_AWS_353: performance_insights_enabled defaults true via config;
  # checkov:skip=CKV_AWS_226: auto_minor_version_upgrade defaults true; checkov cannot
  # checkov:skip=CKV_AWS_118: statically resolve these values through the config object, but
  # the secure defaults are enforced by the module (monitoring_interval defaults to 60) and the
  # secure_defaults test (PCI DSS Req 6/10).
  count = var.config.instance_count

  identifier         = "${var.config.cluster_identifier}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  instance_class     = local.instance_class

  auto_minor_version_upgrade = var.config.auto_minor_version_upgrade

  # PCI DSS Req 10: Performance Insights retains query-level telemetry.
  performance_insights_enabled    = var.config.performance_insights_enabled
  performance_insights_kms_key_id = var.config.performance_insights_kms_key_id

  # PCI DSS Req 10: enhanced OS-level monitoring. monitoring_role_arn must be
  # supplied by the caller when monitoring_interval > 0 (atoms take ARNs as input).
  monitoring_interval = var.config.monitoring_interval
  monitoring_role_arn = var.config.monitoring_role_arn

  tags = local.tags
}
