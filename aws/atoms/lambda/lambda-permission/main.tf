# aws_lambda_permission is not a taggable resource, so there are no module/tag
# locals here. The config.tags field exists only for API uniformity.

resource "aws_lambda_permission" "this" {
  function_name  = var.config.function_name
  statement_id   = var.config.statement_id
  action         = var.config.action
  principal      = var.config.principal
  source_arn     = var.config.source_arn
  source_account = var.config.source_account
}
