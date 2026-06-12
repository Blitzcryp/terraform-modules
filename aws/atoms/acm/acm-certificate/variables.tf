variable "config" {
  description = <<-EOT
    Configuration for the ACM certificate. All inputs live on this single object.
    Secure-by-default values are baked into the optional() fields: DNS validation
    (no manual email click-through, fully automatable) and a strong RSA_2048 key.
    Passing only the required `domain_name` yields a DNS-validated certificate.

    This atom owns ONLY the certificate request — it does not create the DNS
    validation records or wait for issuance. Compose it with the
    `route53/route53-record` and `acm/acm-certificate-validation` atoms (see the
    `components/acm` component) to obtain a fully validated, ISSUED certificate.
  EOT

  type = object({
    domain_name               = string                       # required — primary FQDN on the cert
    subject_alternative_names = optional(list(string), [])   # extra FQDNs (SANs)
    validation_method         = optional(string, "DNS")      # DNS (automatable) or EMAIL
    key_algorithm             = optional(string, "RSA_2048") # key spec
    tags                      = optional(map(string), {})
  })
  # `domain_name` is required, so no `default = {}`.

  validation {
    condition     = length(var.config.domain_name) > 0
    error_message = "config.domain_name must be a non-empty FQDN."
  }

  validation {
    condition     = contains(["DNS", "EMAIL"], var.config.validation_method)
    error_message = "config.validation_method must be either DNS or EMAIL (DNS is recommended — it is fully automatable)."
  }
}
