output "manifest" {
  description = "All outputs of the IAM role atom, collected on a single object."
  value = {
    name      = aws_iam_role.this.name
    arn       = aws_iam_role.this.arn
    id        = aws_iam_role.this.id
    unique_id = aws_iam_role.this.unique_id
  }
}
