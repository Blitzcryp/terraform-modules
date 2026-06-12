output "manifest" {
  description = "All outputs of the acm component, collected on a single object."
  value = {
    # The validated certificate ARN. Sourced from the validation atom so that
    # depending on it guarantees the certificate has reached ISSUED.
    certificate_arn = module.validation.manifest.certificate_arn
    domain_name     = module.certificate.manifest.domain_name

    # FQDNs of the DNS validation records created in the hosted zone.
    validation_record_fqdns = [for r in module.validation_record : r.manifest.fqdn]
  }
}
