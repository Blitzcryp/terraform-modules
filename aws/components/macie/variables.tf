variable "config" {
  description = <<-EOT
    Configuration for the Macie component (sensitive-data discovery for S3). All
    inputs live on this single object. PCI-compliant defaults are baked into the
    optional() fields, so passing `{}` (or omitting config) ENABLES Macie with
    the fastest finding cadence (FIFTEEN_MINUTES) for continuous S3
    sensitive-data (cardholder data) discovery — PCI DSS Req 3 / Req A.

    NOTE: targeted classification jobs (scanning specific buckets on a schedule)
    are defined separately; this component owns only the account-level
    enablement, which is the core continuous-discovery capability.
  EOT

  type = object({
    # Macie account status. ENABLED (default) turns on continuous S3
    # sensitive-data discovery; PAUSED suspends it without deleting findings.
    status = optional(string, "ENABLED")

    # How frequently Macie publishes findings.
    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")

    tags = optional(map(string), {})
  })

  default = {}

  validation {
    condition     = contains(["ENABLED", "PAUSED"], var.config.status)
    error_message = "config.status must be ENABLED or PAUSED."
  }

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.config.finding_publishing_frequency)
    error_message = "config.finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}
