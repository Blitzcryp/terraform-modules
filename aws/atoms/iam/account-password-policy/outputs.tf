output "manifest" {
  description = "All outputs of the account password policy atom, collected on a single object."
  value = {
    minimum_password_length   = aws_iam_account_password_policy.this.minimum_password_length
    expire_passwords          = aws_iam_account_password_policy.this.expire_passwords
    max_password_age          = aws_iam_account_password_policy.this.max_password_age
    password_reuse_prevention = aws_iam_account_password_policy.this.password_reuse_prevention
  }
}
