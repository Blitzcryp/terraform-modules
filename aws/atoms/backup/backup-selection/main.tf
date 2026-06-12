locals {
  # NOTE: aws_backup_selection is not a taggable resource, so var.config.tags is
  # intentionally unused here. The module-identity tag pattern (§5) does not apply
  # because there is no tags argument on the resource. We reference the fields in
  # a local to keep the interface uniform and avoid "declared but unused" noise.
  _accepted_but_unused_tags = var.config.tags
}

resource "aws_backup_selection" "this" {
  name         = var.config.name
  plan_id      = var.config.plan_id
  iam_role_arn = var.config.iam_role_arn

  resources     = var.config.resources
  not_resources = var.config.not_resources

  dynamic "selection_tag" {
    for_each = var.config.selection_tags
    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }
}
