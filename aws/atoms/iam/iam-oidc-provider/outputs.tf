output "manifest" {
  description = "All outputs of the IAM OIDC provider atom, collected on a single object."
  value = {
    arn = aws_iam_openid_connect_provider.this.arn
    url = aws_iam_openid_connect_provider.this.url
  }
}
