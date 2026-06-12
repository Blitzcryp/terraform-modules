locals {
  module_tags = {
    Module = "atoms/ec2/ebs-volume" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Volume encrypted unless the escape hatch is set.
  encrypted = var.config.encrypted && !var.config.allow_unencrypted
}

resource "aws_ebs_volume" "this" {
  # checkov:skip=CKV_AWS_3:Encryption is on by default via local.encrypted; weakening requires config.allow_unencrypted (auditable escape hatch). Checkov cannot resolve the variable-driven value statically.
  availability_zone = var.config.availability_zone
  size              = var.config.size
  type              = var.config.type
  iops              = var.config.iops
  throughput        = var.config.throughput

  # Encryption at rest (PCI DSS Req 3) with an optional CMK.
  encrypted  = local.encrypted
  kms_key_id = var.config.kms_key_arn

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = local.encrypted || var.config.allow_unencrypted
      error_message = "EBS volume encryption disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
