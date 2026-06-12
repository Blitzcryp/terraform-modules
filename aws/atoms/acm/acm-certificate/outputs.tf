output "manifest" {
  description = "All outputs of the ACM certificate atom, collected on a single object."
  value = {
    arn         = aws_acm_certificate.this.arn
    domain_name = aws_acm_certificate.this.domain_name
    status      = aws_acm_certificate.this.status

    # Set of validation records the caller must publish in DNS to prove control of
    # the domain(s). Each element exposes resource_record_name / _type / _value.
    # Feed these into route53-record atoms, then their fqdns into the
    # acm-certificate-validation atom to wait for issuance.
    domain_validation_options = aws_acm_certificate.this.domain_validation_options
  }
}
