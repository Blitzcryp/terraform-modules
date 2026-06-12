output "manifest" {
  description = "All outputs of the IAM group membership atom, collected on a single object."
  value = {
    group = aws_iam_group_membership.this.group
    users = aws_iam_group_membership.this.users
  }
}
