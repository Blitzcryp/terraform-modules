output "manifest" {
  description = "All outputs of the Cognito user pool client atom, collected on a single object. client_secret is sensitive."
  sensitive   = true # client_secret taints the whole object as sensitive
  value = {
    id            = aws_cognito_user_pool_client.this.id
    client_id     = aws_cognito_user_pool_client.this.id
    client_secret = aws_cognito_user_pool_client.this.client_secret
    # Non-secret introspection fields (composing layers verify secure wiring).
    name                = aws_cognito_user_pool_client.this.name
    generate_secret     = aws_cognito_user_pool_client.this.generate_secret
    explicit_auth_flows = aws_cognito_user_pool_client.this.explicit_auth_flows
    allowed_oauth_flows = aws_cognito_user_pool_client.this.allowed_oauth_flows
  }
}
