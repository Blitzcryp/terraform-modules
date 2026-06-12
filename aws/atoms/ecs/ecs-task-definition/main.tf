locals {
  module_tags = {
    Module = "atoms/ecs/ecs-task-definition" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.config.family
  container_definitions    = var.config.container_definitions
  cpu                      = var.config.cpu
  memory                   = var.config.memory
  network_mode             = var.config.network_mode
  requires_compatibilities = var.config.requires_compatibilities

  # Roles passed in by the caller. The execution role pulls images and, crucially,
  # reads secrets from Secrets Manager/SSM for the container `secrets` block
  # (PCI DSS Req 3/8 — secrets are never embedded in the task definition itself).
  execution_role_arn = var.config.execution_role_arn
  task_role_arn      = var.config.task_role_arn

  dynamic "volume" {
    for_each = var.config.volumes
    content {
      name      = volume.value.name
      host_path = try(volume.value.host_path, null)
    }
  }

  dynamic "runtime_platform" {
    for_each = var.config.runtime_platform == null ? [] : [var.config.runtime_platform]
    content {
      operating_system_family = runtime_platform.value.operating_system_family
      cpu_architecture        = runtime_platform.value.cpu_architecture
    }
  }

  tags = local.tags
}
