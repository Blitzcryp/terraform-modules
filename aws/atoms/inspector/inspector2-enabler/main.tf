data "aws_caller_identity" "current" {}

locals {
  # Default to the current account when no explicit account list is given.
  account_ids = length(var.config.account_ids) > 0 ? var.config.account_ids : [data.aws_caller_identity.current.account_id]
}

# Enables Amazon Inspector v2 continuous vulnerability scanning (PCI DSS Req 6/11).
resource "aws_inspector2_enabler" "this" {
  account_ids    = local.account_ids
  resource_types = var.config.resource_types
}
