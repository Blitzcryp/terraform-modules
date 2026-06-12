locals {
  module_tags = {
    Module = "atoms/rds/rds-parameter-group" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_db_parameter_group" "this" {
  name        = var.config.name
  family      = var.config.family
  description = var.config.description

  dynamic "parameter" {
    for_each = var.config.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
