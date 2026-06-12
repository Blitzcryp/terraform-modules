# NOTE: aws_iam_group_membership is NOT a taggable resource — it accepts no
# `tags` argument (it is a pure association). The config object therefore omits
# `tags`. Documented here for uniformity with the tagging convention.
#
# This resource manages the group's membership EXCLUSIVELY: users present in the
# group but absent from config.users are removed on apply.

resource "aws_iam_group_membership" "this" {
  name  = var.config.name
  group = var.config.group
  users = var.config.users
}
