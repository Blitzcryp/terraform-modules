locals {
  module_tags = {
    Module = "atoms/alb/lb-target-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_lb_target_group" "this" {
  name                 = var.config.name
  port                 = var.config.port
  protocol             = var.config.protocol
  vpc_id               = var.config.vpc_id
  target_type          = var.config.target_type
  deregistration_delay = var.config.deregistration_delay

  health_check {
    enabled             = true
    path                = var.config.health_check.path
    port                = var.config.health_check.port
    protocol            = var.config.health_check.protocol
    matcher             = var.config.health_check.matcher
    interval            = var.config.health_check.interval
    timeout             = var.config.health_check.timeout
    healthy_threshold   = var.config.health_check.healthy_threshold
    unhealthy_threshold = var.config.health_check.unhealthy_threshold
  }

  tags = local.tags
}
