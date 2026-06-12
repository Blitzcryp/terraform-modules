output "manifest" {
  description = "All outputs of the Route53 zone atom, collected on a single object."
  value = {
    zone_id      = aws_route53_zone.this.zone_id
    arn          = aws_route53_zone.this.arn
    name         = aws_route53_zone.this.name
    name_servers = aws_route53_zone.this.name_servers
  }
}
