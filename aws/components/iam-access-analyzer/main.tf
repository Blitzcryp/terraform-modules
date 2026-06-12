locals {
  module_tags = {
    Module = "components/iam-access-analyzer" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# --- IAM Access Analyzer (external-access detection) --------------------------
# Composes the accessanalyzer-analyzer atom. The analyzer continuously evaluates
# resource-based policies and reports access granted to principals outside the
# zone of trust (PCI DSS Req 7 — restrict access by business need-to-know).
# Findings surface in the IAM console and (when enabled) Security Hub; routing
# them to SNS is the job of the findings-notification component, not this one.
module "analyzer" {
  source = "../../atoms/accessanalyzer/accessanalyzer-analyzer"

  config = {
    name = var.config.name
    type = var.config.type
    tags = var.config.tags
  }
}
