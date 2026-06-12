# This atom represents the "wait until ACM reports the certificate as ISSUED"
# step. It is a virtual resource: it creates nothing in AWS, it blocks apply
# until ACM has seen the DNS validation records (supplied as fqdns) and finished
# validation. The caller owns the certificate and the validation records.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = var.config.certificate_arn
  validation_record_fqdns = var.config.validation_record_fqdns
}
