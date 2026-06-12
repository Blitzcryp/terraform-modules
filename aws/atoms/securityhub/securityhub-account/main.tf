data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  # Module-identity tag only; global tags come from provider default_tags.
  # NOTE: aws_securityhub_account / _standards_subscription do not accept tags,
  # so config.tags is accepted for interface uniformity but cannot be applied to
  # these resources. It is surfaced in the manifest for composition convenience.
  module_tags = {
    Module = "atoms/securityhub/securityhub-account"
  }
  tags = merge(local.module_tags, var.config.tags)

  region    = data.aws_region.current.name
  partition = data.aws_partition.current.partition

  # Region/partition-aware ARNs for the two AWS-curated default standards.
  # CIS AWS Foundations Benchmark v1.2.0 is a regionless ruleset ARN; AWS
  # Foundational Security Best Practices is a region-scoped standards ARN.
  default_standard_arns = [
    "arn:${local.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
    "arn:${local.partition}:securityhub:${local.region}::standards/aws-foundational-security-best-practices/v/1.0.0",
  ]

  # Subscribe to the explicit list when supplied; otherwise the curated defaults
  # but only when enable_default_standards is true. Empty list = no subscriptions.
  effective_standard_arns = var.config.standards_arns != null ? var.config.standards_arns : (
    var.config.enable_default_standards ? local.default_standard_arns : []
  )
}

# Enables Security Hub CSPM in the current account (PCI DSS Req 6/10/11).
resource "aws_securityhub_account" "this" {
  enable_default_standards  = var.config.enable_default_standards
  control_finding_generator = var.config.control_finding_generator
  auto_enable_controls      = var.config.auto_enable_controls
}

# Tightly-coupled standards subscriptions: meaningless without the hub above.
resource "aws_securityhub_standards_subscription" "this" {
  for_each      = toset(local.effective_standard_arns)
  standards_arn = each.value

  depends_on = [aws_securityhub_account.this]
}
