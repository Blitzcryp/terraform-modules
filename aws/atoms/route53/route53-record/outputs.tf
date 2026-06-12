output "manifest" {
  description = "All outputs of the Route53 record atom, collected on a single object."
  value = {
    fqdn      = aws_route53_record.this.fqdn
    name      = aws_route53_record.this.name
    record_id = aws_route53_record.this.id
  }
}
