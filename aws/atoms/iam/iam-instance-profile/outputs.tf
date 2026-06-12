output "manifest" {
  description = "All outputs of the IAM instance profile atom, collected on a single object."
  value = {
    arn       = aws_iam_instance_profile.this.arn
    name      = aws_iam_instance_profile.this.name
    id        = aws_iam_instance_profile.this.id
    unique_id = aws_iam_instance_profile.this.unique_id
  }
}
