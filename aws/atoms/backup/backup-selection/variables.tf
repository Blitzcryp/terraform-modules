variable "config" {
  description = <<-EOT
    Configuration for the AWS Backup selection atom. A selection binds a set of
    resources (by ARN and/or by tag) to a backup plan, assuming the supplied IAM
    role to perform the backups (PCI DSS Req 7 least privilege). All inputs live
    on this single object.

    NOTE on tags: aws_backup_selection is NOT a taggable resource. A `tags` field
    is accepted on this config for interface uniformity across the library, but
    it is intentionally NOT applied to the resource (there is nowhere to put it).
    Use `selection_tags` to choose which tagged resources are backed up.
  EOT

  type = object({
    # All three are REQUIRED: the selection is meaningless without a name, a plan
    # to attach to, and the role used to perform the backups.
    name         = string
    plan_id      = string
    iam_role_arn = string

    # What to back up: explicit ARNs, exclusions, and/or tag-based matching.
    resources     = optional(list(string), [])
    not_resources = optional(list(string), [])
    selection_tags = optional(list(object({
      type  = optional(string, "STRINGEQUALS")
      key   = string
      value = string
    })), [])

    # Accepted for interface uniformity only; NOT applied (resource not taggable).
    tags = optional(map(string), {})
  })

  # no `default` here because name, plan_id and iam_role_arn are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::", var.config.iam_role_arn))
    error_message = "config.iam_role_arn must be a valid IAM role ARN (arn:aws:iam::...)."
  }

  validation {
    condition     = length(var.config.resources) > 0 || length(var.config.selection_tags) > 0
    error_message = "A selection must target something: set config.resources and/or config.selection_tags."
  }

  validation {
    condition     = alltrue([for t in var.config.selection_tags : contains(["STRINGEQUALS"], t.type)])
    error_message = "Each selection_tags.type must be STRINGEQUALS."
  }
}
