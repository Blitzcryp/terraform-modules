locals {
  module_tags = {
    Module = "atoms/mq/mq-broker" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  use_cmk = var.config.kms_key_arn != null

  # Audit logging is only supported by ActiveMQ; silently drop it for RabbitMQ.
  audit_logs_effective = var.config.engine_type == "ActiveMQ" ? var.config.audit_logs : false

  # engine_version is required by AWS. When the caller does not pin one, fall back
  # to a current default for the chosen engine.
  default_engine_version = var.config.engine_type == "RabbitMQ" ? "3.13" : "5.18"
  engine_version         = coalesce(var.config.engine_version, local.default_engine_version)
}

resource "aws_mq_broker" "this" {
  # checkov:skip=CKV_AWS_48: General (and ActiveMQ audit) logging is enabled by the
  #   logs block via secure optional() defaults (general_logs=true); checkov cannot
  #   resolve object-type optional() defaults through the module call (false
  #   positive). Verified by tests/defaults.tftest.hcl. Exceptions: security@emag.ro.
  # checkov:skip=CKV_AWS_207: Minor version auto-upgrade defaults to true
  #   (config.auto_minor_version_upgrade); checkov cannot resolve the optional()
  #   default through the module call (false positive). Verified by tests.
  # checkov:skip=CKV_AWS_197: ActiveMQ audit logging is enabled by the logs block
  #   via secure optional() defaults (audit_logs=true, gated to ActiveMQ); checkov
  #   cannot resolve the object-type optional() default through the module call
  #   (false positive). Verified by tests/defaults.tftest.hcl. Exceptions: security@emag.ro.
  broker_name                = var.config.broker_name
  engine_type                = var.config.engine_type
  engine_version             = local.engine_version
  host_instance_type         = var.config.host_instance_type
  deployment_mode            = var.config.deployment_mode
  auto_minor_version_upgrade = var.config.auto_minor_version_upgrade
  publicly_accessible        = var.config.publicly_accessible
  subnet_ids                 = var.config.subnet_ids
  security_groups            = var.config.security_groups

  # Encryption at rest (PCI DSS Req 3). Prefer a customer-managed CMK; otherwise
  # fall back to the AWS-owned key only when explicitly permitted.
  encryption_options {
    kms_key_id        = var.config.kms_key_arn
    use_aws_owned_key = !local.use_cmk
  }

  # Logging (PCI DSS Req 10). audit only emitted for ActiveMQ.
  logs {
    general = var.config.general_logs
    audit   = local.audit_logs_effective
  }

  # Broker users (PCI DSS Req 8). Passwords are sourced from a secrets manager by
  # the caller; this module never hardcodes a password.
  dynamic "user" {
    for_each = var.config.users
    content {
      username       = user.value.username
      password       = user.value.password
      console_access = user.value.console_access
      groups         = user.value.groups
    }
  }

  tags = local.tags

  lifecycle {
    # PCI DSS Req 1: broker must not be public unless explicitly permitted.
    precondition {
      condition     = !var.config.publicly_accessible || var.config.allow_public
      error_message = "Broker is publicly_accessible without config.allow_public=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # PCI DSS Req 3: prefer a customer-managed CMK over the AWS-owned key.
    precondition {
      condition     = local.use_cmk || var.config.allow_aws_owned_key
      error_message = "No customer-managed KMS key provided. Set config.kms_key_arn, or file a PCI exception (security@emag.ro) and set config.allow_aws_owned_key=true to accept the AWS-owned key."
    }
  }
}
