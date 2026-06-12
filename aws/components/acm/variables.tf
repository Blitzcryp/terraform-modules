variable "config" {
  description = <<-EOT
    Configuration for the acm component: a fully DNS-validated, ISSUED ACM
    certificate. All inputs live on this single object. Passing the required
    `domain_name` and `hosted_zone_id` yields a certificate whose DNS validation
    records are created in the supplied Route53 hosted zone and which is waited on
    until ACM reports it ISSUED.

    This component composes atoms via module blocks:
      - acm/acm-certificate            (requests the DNS-validated cert)
      - route53/route53-record         (one validation CNAME per domain/SAN)
      - acm/acm-certificate-validation (blocks until the cert is ISSUED)

    The caller MUST own the hosted zone identified by `hosted_zone_id` and it must
    be authoritative for `domain_name` (and every SAN) so ACM can resolve the
    validation records.
  EOT

  type = object({
    domain_name               = string                     # required — primary FQDN on the cert
    subject_alternative_names = optional(list(string), []) # extra FQDNs (SANs)
    hosted_zone_id            = string                     # required — Route53 zone for validation records
    tags                      = optional(map(string), {})
  })
  # `domain_name` and `hosted_zone_id` are required, so no `default = {}`.

  validation {
    condition     = length(var.config.domain_name) > 0
    error_message = "config.domain_name must be a non-empty FQDN."
  }

  validation {
    condition     = length(var.config.hosted_zone_id) > 0
    error_message = "config.hosted_zone_id must be a non-empty Route53 hosted zone id."
  }
}
