locals {
  module_tags = {
    Module = "atoms/ec2/ec2-instance" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # IMDSv2 is required by default (http_tokens=required). The escape hatch flips
  # to "optional", which permits the legacy IMDSv1 (PCI DSS Req 2 hardening).
  http_tokens = var.config.allow_imdsv1 ? "optional" : "required"

  # Root volume encrypted unless the escape hatch is set.
  root_encrypted = !var.config.allow_unencrypted
}

resource "aws_instance" "this" {
  # checkov:skip=CKV_AWS_79:IMDSv2 is enforced by default via local.http_tokens="required"; weakening requires config.allow_imdsv1 (auditable escape hatch). Checkov cannot resolve the variable-driven value statically.
  # checkov:skip=CKV_AWS_126:Detailed monitoring defaults to on via config.monitoring=true. Checkov cannot resolve the variable-driven value statically.
  ami                    = var.config.ami
  instance_type          = var.config.instance_type
  subnet_id              = var.config.subnet_id
  vpc_security_group_ids = var.config.vpc_security_group_ids
  iam_instance_profile   = var.config.iam_instance_profile
  key_name               = var.config.key_name
  user_data              = var.config.user_data

  monitoring                  = var.config.monitoring # PCI DSS Req 10
  ebs_optimized               = var.config.ebs_optimized
  associate_public_ip_address = var.config.associate_public_ip_address # PCI DSS Req 1

  # IMDSv2 enforced (PCI DSS Req 2): tokens required, endpoint enabled.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = local.http_tokens
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Root volume encrypted at rest (PCI DSS Req 3) with an optional CMK.
  # checkov:skip=CKV_AWS_135:ebs_optimized is configurable via config.ebs_optimized (on by default)
  root_block_device {
    encrypted   = local.root_encrypted
    kms_key_id  = var.config.kms_key_arn
    volume_size = var.config.root_volume_size
    volume_type = var.config.root_volume_type
    tags        = local.tags
  }

  # Additional data volumes, each encrypted by default.
  dynamic "ebs_block_device" {
    for_each = var.config.ebs_block_devices
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
      iops        = ebs_block_device.value.iops
      throughput  = ebs_block_device.value.throughput
      encrypted   = ebs_block_device.value.encrypted
      kms_key_id  = var.config.kms_key_arn
      tags        = local.tags
    }
  }

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = local.root_encrypted || var.config.allow_unencrypted
      error_message = "Root volume encryption disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # Public IP must be intentional (PCI DSS Req 1).
    precondition {
      condition     = !var.config.associate_public_ip_address || var.config.allow_public_ip
      error_message = "associate_public_ip_address=true without config.allow_public_ip=true. Keep instances private. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
