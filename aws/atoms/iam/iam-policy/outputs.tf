output "manifest" {
  description = "All outputs of the IAM policy atom, collected on a single object."
  value = {
    arn       = aws_iam_policy.this.arn
    name      = aws_iam_policy.this.name
    id        = aws_iam_policy.this.id
    policy_id = aws_iam_policy.this.policy_id
  }
}
