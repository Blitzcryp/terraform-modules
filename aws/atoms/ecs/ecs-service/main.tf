locals {
  module_tags = {
    Module = "atoms/ecs/ecs-service" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Effective values: an insecure choice only takes effect when its escape hatch is set.
  assign_public_ip       = var.config.assign_public_ip && var.config.allow_public_ip
  enable_execute_command = var.config.enable_execute_command && var.config.allow_execute_command

  # The circuit breaker is only valid with the ECS deployment controller.
  use_ecs_controller = var.config.deployment_controller_type == "ECS"
}

resource "aws_ecs_service" "this" {
  name            = var.config.name
  cluster         = var.config.cluster_arn
  task_definition = var.config.task_definition
  desired_count   = var.config.desired_count
  launch_type     = var.config.launch_type

  # ECS Exec gated behind an escape hatch (PCI DSS Req 7: restrict access).
  enable_execute_command = local.enable_execute_command

  propagate_tags                    = var.config.propagate_tags
  health_check_grace_period_seconds = var.config.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.config.subnet_ids
    security_groups  = var.config.security_group_ids
    assign_public_ip = local.assign_public_ip # false by default (PCI DSS Req 1)
  }

  deployment_controller {
    type = var.config.deployment_controller_type
  }

  # Automatic rollback on failed deployments — only valid for the ECS controller.
  dynamic "deployment_circuit_breaker" {
    for_each = local.use_ecs_controller ? [1] : []
    content {
      enable   = true
      rollback = true
    }
  }

  dynamic "load_balancer" {
    for_each = var.config.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  tags = local.tags

  lifecycle {
    # A public IP on task ENIs exposes them to the internet (PCI DSS Req 1).
    precondition {
      condition     = !var.config.assign_public_ip || var.config.allow_public_ip
      error_message = "assign_public_ip=true without config.allow_public_ip=true. Tasks should stay in private subnets. File a PCI exception (security@emag.ro) and set the flag."
    }

    # ECS Exec is an interactive backdoor into running containers (PCI DSS Req 7).
    precondition {
      condition     = !var.config.enable_execute_command || var.config.allow_execute_command
      error_message = "enable_execute_command=true without config.allow_execute_command=true. ECS Exec is a debugging backdoor. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
