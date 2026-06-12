output "manifest" {
  description = "All outputs of the IAM user atom, collected on a single object."
  value = {
    arn       = aws_iam_user.this.arn
    name      = aws_iam_user.this.name
    unique_id = aws_iam_user.this.unique_id
    path      = aws_iam_user.this.path
  }
}
