output "manifest" {
  description = "All outputs of the Secrets Manager secret atom, collected on a single object."
  value = {
    secret_arn  = aws_secretsmanager_secret.this.arn
    secret_id   = aws_secretsmanager_secret.this.id
    secret_name = aws_secretsmanager_secret.this.name
  }
}
