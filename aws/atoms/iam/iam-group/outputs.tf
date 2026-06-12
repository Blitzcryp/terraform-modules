output "manifest" {
  description = "All outputs of the IAM group atom, collected on a single object."
  value = {
    arn       = aws_iam_group.this.arn
    name      = aws_iam_group.this.name
    id        = aws_iam_group.this.id
    unique_id = aws_iam_group.this.unique_id
  }
}
