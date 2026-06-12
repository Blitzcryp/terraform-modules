output "manifest" {
  description = "All outputs of the Lambda permission atom, collected on a single object."
  value = {
    id           = aws_lambda_permission.this.id
    statement_id = aws_lambda_permission.this.statement_id
  }
}
