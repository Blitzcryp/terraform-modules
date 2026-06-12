locals {
  module_tags = {
    Module = "atoms/ec2/launch-template" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # IMDSv2 is required by default (http_tokens=required). The escape hatch flips
  # to "optional", which permits the legacy IMDSv1 (PCI DSS Req 2 hardening).
  http_tokens = var.config.allow_imdsv1 ? "optional" : "required"

  # Root volume encrypted unless the escape hatch is set.
  root_encrypted = !var.config.allow_unencrypted
}

resource "aws_launch_template" "this" {
  # checkov:skip=CKV_AWS_341:http_put_response_hop_limit defaults to 1; a higher value is not configured here.
  name                   = var.config.name
  image_id               = var.config.image_id
  instance_type          = var.config.instance_type
  vpc_security_group_ids = var.config.vpc_security_group_ids
  key_name               = var.config.key_name
  user_data              = var.config.user_data
  update_default_version = true

  dynamic "iam_instance_profile" {
    for_each = var.config.iam_instance_profile_arn == null ? [] : [var.config.iam_instance_profile_arn]
    content {
      arn = iam_instance_profile.value
    }
  }

  # IMDSv2 enforced (PCI DSS Req 2): tokens required, endpoint enabled.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = local.http_tokens
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Detailed CloudWatch monitoring (PCI DSS Req 10).
  monitoring {
    enabled = true
  }

  # Root volume encrypted at rest (PCI DSS Req 3) with an optional CMK.
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.config.root_volume_size
      volume_type           = var.config.root_volume_type
      encrypted             = tostring(local.root_encrypted)
      kms_key_id            = var.config.kms_key_arn
      delete_on_termination = "true"
    }
  }

  # Propagate tags to launched instances and volumes (PCI DSS Req 1: traceability).
  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  tags = local.tags

  lifecycle {
    # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
    precondition {
      condition     = local.root_encrypted || var.config.allow_unencrypted
      error_message = "Root volume encryption disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
