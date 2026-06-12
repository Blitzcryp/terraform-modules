output "manifest" {
  description = "All outputs of the IAM group policy attachment atom, collected on a single object."
  value = {
    id         = aws_iam_group_policy_attachment.this.id
    group      = aws_iam_group_policy_attachment.this.group
    policy_arn = aws_iam_group_policy_attachment.this.policy_arn
  }
}
