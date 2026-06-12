variable "config" {
  description = <<-EOT
    Configuration for the iam-group component (an IAM group with attached managed
    policies and members). All inputs live on this single object; the caller must
    supply the required `name`.

    This component is the group-centric place to manage permissions and
    membership for human/service users (PCI DSS Req 7 least privilege): attach
    managed policies to the group and list the group's members here, rather than
    attaching policies or keys to individual users. The membership is managed
    EXCLUSIVELY — users not listed in `users` are removed from the group on apply.
  EOT

  type = object({
    # name is REQUIRED: the friendly IAM group name. No safe default exists.
    name = string

    path                = optional(string, "/")
    managed_policy_arns = optional(list(string), []) # managed policy ARNs to attach to the group
    users               = optional(list(string), []) # full set of IAM user names that belong to the group
    tags                = optional(map(string), {})
  })

  # no `default` here because name is required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for arn in var.config.managed_policy_arns :
      can(regex("^arn:aws[a-z-]*:iam::(aws|[0-9]{12}):policy/", arn))
    ])
    error_message = "Each config.managed_policy_arns entry must be a valid IAM policy ARN (arn:aws:iam::<account|aws>:policy/...)."
  }
}
