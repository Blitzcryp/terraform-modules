variable "config" {
  description = <<-EOT
    Configuration for the IAM Access Analyzer. All inputs live on this single
    object. The analyzer name is required (no sensible default for an
    account-level singleton); the type defaults to the PCI-compliant
    external-access analyzer scoped to the current ACCOUNT. Access Analyzer
    continuously detects resource policies that grant access to external — or,
    for the *_UNUSED_ACCESS types, unused — principals (PCI DSS Req 7).
  EOT

  type = object({
    # REQUIRED: the analyzer name. The caller must decide it. No default.
    name = string

    # Zone of trust / analyzer scope. ACCOUNT (default) reports access granted to
    # principals outside the account; the UNUSED_ACCESS variants report unused
    # access; the ORGANIZATION variants widen the zone of trust to the whole org.
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
