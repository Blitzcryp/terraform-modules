output "manifest" {
  description = "All outputs of the ALB atom, collected on a single object."
  value = {
    id         = aws_lb.this.id
    arn        = aws_lb.this.arn
    dns_name   = aws_lb.this.dns_name
    zone_id    = aws_lb.this.zone_id
    arn_suffix = aws_lb.this.arn_suffix
  }
}
