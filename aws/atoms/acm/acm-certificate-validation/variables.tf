variable "config" {
  description = <<-EOT
    Configuration for the ACM certificate validation. All inputs live on this
    single object. This atom does not create AWS resources — it blocks `apply`
    until ACM reports the referenced certificate as ISSUED, after the supplied
    DNS validation record FQDNs have been published.

    Compose it with the `acm/acm-certificate` and `route53/route53-record` atoms:
    create the cert, publish its domain_validation_options as DNS records, then
    feed those record FQDNs here (see the `components/acm` component).
  EOT

  type = object({
    certificate_arn         = string                     # required — ARN of the acm-certificate to validate
    validation_record_fqdns = optional(list(string), []) # FQDNs of the published DNS validation records
  })
  # `certificate_arn` is required, so no `default = {}`.

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:acm:", var.config.certificate_arn))
    error_message = "config.certificate_arn must be a valid ACM certificate ARN (arn:aws:acm:...)."
  }
}
