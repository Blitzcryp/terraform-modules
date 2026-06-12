# NOTE: aws_iam_group_policy_attachment is NOT a taggable resource — it accepts
# no `tags` argument (it is a pure association). The config object therefore
# omits `tags`. Documented here for uniformity with the tagging convention.

resource "aws_iam_group_policy_attachment" "this" {
  group      = var.config.group
  policy_arn = var.config.policy_arn
}
