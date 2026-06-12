variable "config" {
  description = <<-EOT
    Configuration for the IAM group membership atom. All inputs live on this
    single object — all three fields are required.

    IMPORTANT: aws_iam_group_membership manages the group's FULL membership
    exclusively. Any user in the group that is not listed in `users` will be
    REMOVED on apply. There is exactly one membership resource per group.
  EOT

  type = object({
    # All required: there is no safe default for "who belongs to this group".
    name  = string       # the membership resource name (identifier for this attachment)
    group = string       # the IAM group name to manage membership of
    users = list(string) # the complete set of IAM user names in the group
  })

  # no `default` here because all fields are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.group) > 0
    error_message = "config.group must be a non-empty string."
  }
}
