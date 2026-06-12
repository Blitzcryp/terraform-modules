variable "config" {
  description = <<-EOT
    Configuration for the AWS Security Hub account enabler. All inputs live on
    this single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so passing `{}` (or omitting config entirely) enables Security Hub
    with consolidated control findings, auto-enabled new controls, and a
    subscription to the CIS AWS Foundations Benchmark and AWS Foundational
    Security Best Practices standards (PCI DSS Req 6/10/11 continuous posture).
  EOT

  type = object({
    # Activate the two AWS-curated default standards (CIS + FSBP).
    enable_default_standards = optional(bool, true)

    # Explicit standard ARNs to subscribe to. Defaults to null so the atom builds
    # a region/partition-aware list for CIS AWS Foundations + AWS Foundational
    # Security Best Practices. Pass a list to override the standards subscribed.
    standards_arns = optional(list(string))

    # Consolidate findings across standards (SECURITY_CONTROL) vs one per
    # standard (STANDARD_CONTROL). Consolidation is the AWS-recommended posture.
    control_finding_generator = optional(string, "SECURITY_CONTROL")

    # Automatically enable new controls as AWS adds them to enabled standards.
    auto_enable_controls = optional(bool, true)

    tags = optional(map(string), {})
  })

  default = {}

  validation {
    condition     = contains(["SECURITY_CONTROL", "STANDARD_CONTROL"], var.config.control_finding_generator)
    error_message = "config.control_finding_generator must be SECURITY_CONTROL or STANDARD_CONTROL."
  }
}
