locals {
  module_tags = {
    Module = "atoms/vpc/vpc" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  create_flow_log = var.config.enable_flow_logs
}

resource "aws_vpc" "this" {
  cidr_block           = var.config.cidr_block
  instance_tenancy     = var.config.instance_tenancy
  enable_dns_support   = var.config.enable_dns_support
  enable_dns_hostnames = var.config.enable_dns_hostnames

  tags = merge(local.tags, { Name = var.config.name })

  # Network traffic logging must be intentional to disable (PCI DSS Req 10).
  lifecycle {
    precondition {
      condition     = var.config.enable_flow_logs || var.config.allow_flow_logs_disabled
      error_message = "VPC Flow Logs disabled without config.allow_flow_logs_disabled=true. File a PCI exception (security@emag.ro) and set the flag."
    }

    # When flow logs are enabled, the caller must supply a destination ARN
    # (this atom does not create the destination).
    precondition {
      condition     = !var.config.enable_flow_logs || var.config.flow_log_destination_arn != null
      error_message = "enable_flow_logs=true requires config.flow_log_destination_arn (CloudWatch Log Group ARN or S3 bucket ARN). This atom does not create the destination — supply an existing one."
    }

    # CloudWatch Logs delivery needs a flow-log IAM role.
    precondition {
      condition     = !var.config.enable_flow_logs || var.config.flow_log_destination_type != "cloud-watch-logs" || var.config.flow_log_iam_role_arn != null
      error_message = "config.flow_log_destination_type='cloud-watch-logs' requires config.flow_log_iam_role_arn for log delivery."
    }
  }
}

# Tightly-coupled: lock the default SG to NO rules (PCI DSS Req 1 / CIS — the
# default security group must allow no traffic). Declaring it with empty
# ingress/egress adopts and strips the implicit default rules.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress = []
  egress  = []

  tags = merge(local.tags, { Name = "${var.config.name}-default-locked" })
}

# Optional, tightly-coupled: VPC Flow Logs. Destination + IAM role are inputs;
# this atom does not create the log group / bucket / role.
resource "aws_flow_log" "this" {
  count = local.create_flow_log ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = var.config.flow_log_traffic_type
  log_destination_type = var.config.flow_log_destination_type
  log_destination      = var.config.flow_log_destination_arn
  iam_role_arn         = var.config.flow_log_destination_type == "cloud-watch-logs" ? var.config.flow_log_iam_role_arn : null

  tags = merge(local.tags, { Name = "${var.config.name}-flow-log" })
}
