output "manifest" {
  description = "All outputs of the RDS Proxy atom, collected on a single object."
  value = {
    arn      = aws_db_proxy.this.arn
    name     = aws_db_proxy.this.name
    endpoint = aws_db_proxy.this.endpoint
  }
}
