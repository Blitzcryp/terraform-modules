locals {
  module_tags = {
    Module = "atoms/accessanalyzer/accessanalyzer-analyzer" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# Enables an IAM Access Analyzer in the current account/region. Continuously
# analyses resource-based policies to detect access granted to external (or,
# for *_UNUSED_ACCESS analyzers, unused) principals — PCI DSS Req 7
# (restrict access to system components by business need-to-know).
resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = var.config.name
  type          = var.config.type

  tags = local.tags
}
