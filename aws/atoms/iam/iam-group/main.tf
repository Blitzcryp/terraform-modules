# NOTE: aws_iam_group is NOT a taggable resource — it accepts no `tags`
# argument. The config object therefore omits `tags` (unlike most atoms). Group
# identity carries no per-instance tags; ownership is traceable via the group
# path/name. This is documented here for uniformity with the tagging convention.

resource "aws_iam_group" "this" {
  name = var.config.name
  path = var.config.path
}
