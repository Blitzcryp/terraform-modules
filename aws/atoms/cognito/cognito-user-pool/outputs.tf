output "manifest" {
  description = "All outputs of the Cognito user pool atom, collected on a single object."
  value = {
    id       = aws_cognito_user_pool.this.id
    arn      = aws_cognito_user_pool.this.arn
    endpoint = aws_cognito_user_pool.this.endpoint
    name     = aws_cognito_user_pool.this.name
  }
}
