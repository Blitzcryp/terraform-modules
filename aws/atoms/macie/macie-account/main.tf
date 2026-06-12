locals {
  # Module-identity tag only; global tags come from provider default_tags.
  # NOTE: aws_macie2_account does not accept tags, so config.tags is accepted for
  # interface uniformity but cannot be applied to this resource. It is surfaced
  # in the manifest for composition convenience.
  module_tags = {
    Module = "atoms/macie/macie-account"
  }
  tags = merge(local.module_tags, var.config.tags)
}

# Enables Amazon Macie in the current account. Macie continuously discovers,
# classifies and reports on sensitive data (e.g. cardholder data) stored in S3
# — PCI DSS Req 3 (protect stored account data) / Req A (discover where
# sensitive data resides). ENABLED + FIFTEEN_MINUTES are the secure defaults.
resource "aws_macie2_account" "this" {
  status                       = var.config.status
  finding_publishing_frequency = var.config.finding_publishing_frequency
}
