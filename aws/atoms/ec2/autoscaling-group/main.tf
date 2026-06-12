locals {
  module_tags = {
    Module = "atoms/ec2/autoscaling-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_autoscaling_group" "this" {
  name                = var.config.name
  vpc_zone_identifier = var.config.vpc_zone_identifier

  min_size         = var.config.min_size
  max_size         = var.config.max_size
  desired_capacity = var.config.desired_capacity

  health_check_type         = var.config.health_check_type
  health_check_grace_period = var.config.health_check_grace_period

  target_group_arns = var.config.target_group_arns

  launch_template {
    id      = var.config.launch_template_id
    version = var.config.launch_template_version
  }

  # ASGs take tags as repeated tag {} blocks (not a map). Each merged tag is
  # propagated to launched instances so they stay traceable (PCI DSS Req 1).
  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    # Replace instances on launch-template changes without manual cycling.
    create_before_destroy = true
  }
}
