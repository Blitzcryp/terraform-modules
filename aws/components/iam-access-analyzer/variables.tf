variable "config" {
  description = <<-EOT
    Configuration for the IAM Access Analyzer component (external-access
    detection). All inputs live on this single object. The analyzer name is
    required; the type defaults to the account-scoped external-access analyzer.
    Access Analyzer continuously detects resource policies granting access to
    external — or, for the *_UNUSED_ACCESS types, unused — principals
    (PCI DSS Req 7).

    NOTE: findings surface in the IAM console and, when Security Hub is enabled,
    are aggregated there. Routing findings to an SNS topic requires the
    findings-notification component; this component does not wire that.
  EOT

  type = object({
    # REQUIRED: the analyzer name. The caller must decide it. No default.
    name = string

    # Analyzer scope. ACCOUNT (default) reports external access; the
    # *_UNUSED_ACCESS variants report unused access; the ORGANIZATION variants
    # widen the zone of trust to the whole organization.
    type = optional(string, "ACCOUNT")

    tags = optional(map(string), {})
  })

  # no `default` here because `name` is required

  validation {
    condition = contains(
      ["ACCOUNT", "ORGANIZATION", "ACCOUNT_UNUSED_ACCESS", "ORGANIZATION_UNUSED_ACCESS"],
      var.config.type
    )
    error_message = "config.type must be ACCOUNT, ORGANIZATION, ACCOUNT_UNUSED_ACCESS, or ORGANIZATION_UNUSED_ACCESS."
  }
}
