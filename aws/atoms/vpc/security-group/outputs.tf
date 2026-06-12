output "manifest" {
  description = "All outputs of the security group atom, collected on a single object."
  value = {
    id   = aws_security_group.this.id
    arn  = aws_security_group.this.arn
    name = aws_security_group.this.name
  }
}
