output "manifest" {
  description = "All outputs of the Cognito user pool domain atom, collected on a single object."
  value = {
    id                          = aws_cognito_user_pool_domain.this.id
    domain                      = aws_cognito_user_pool_domain.this.domain
    cloudfront_distribution_arn = try(aws_cognito_user_pool_domain.this.cloudfront_distribution_arn, null)
    aws_account_id              = try(aws_cognito_user_pool_domain.this.aws_account_id, null)
  }
}
