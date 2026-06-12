locals {
  module_tags = {
    Module = "components/macie" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

# --- Amazon Macie account enablement (sensitive-data discovery for S3) ---------
# Composes the macie-account atom. Enabling Macie at the account level is the
# core PCI value: continuous, automated discovery and classification of
# sensitive data (e.g. cardholder data) stored in S3 — PCI DSS Req 3 (protect
# stored account data) / Req A (know where sensitive data resides).
#
# NOTE: targeted classification jobs (aws_macie2_classification_job) that scan
# specific buckets on a schedule are defined separately and are out of scope for
# this component, which owns only the account-level enablement.
module "macie_account" {
  source = "../../atoms/macie/macie-account"

  config = {
    status                       = var.config.status
    finding_publishing_frequency = var.config.finding_publishing_frequency
    tags                         = var.config.tags
  }
}
