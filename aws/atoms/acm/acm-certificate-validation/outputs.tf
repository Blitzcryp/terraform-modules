output "manifest" {
  description = "All outputs of the ACM certificate validation atom, collected on a single object."
  value = {
    # The validated certificate ARN. Depending on this output guarantees the
    # certificate has reached ISSUED before downstream resources (e.g. an HTTPS
    # listener) use it.
    certificate_arn = aws_acm_certificate_validation.this.certificate_arn
  }
}
