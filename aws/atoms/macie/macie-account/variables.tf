variable "config" {
  description = <<-EOT
    Configuration for the Amazon Macie account enabler. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so passing `{}` (or omitting config entirely) ENABLES Macie with the
    fastest finding cadence (FIFTEEN_MINUTES) for continuous sensitive-data
    (cardholder data) discovery across S3 — PCI DSS Req 3 / Req A.
  EOT

  type = object({
    # Macie account status. ENABLED (default) turns on continuous S3
    # sensitive-data discovery; PAUSED suspends it without deleting findings.
    status = optional(string, "ENABLED")

    # How frequently Macie publishes findings.
    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")

    # Kept for interface uniformity. NOTE: aws_macie2_account does not accept
    # tags; this field cannot be applied to the resource and is surfaced in the
    # manifest only.
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
