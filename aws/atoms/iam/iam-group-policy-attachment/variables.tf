variable "config" {
  description = <<-EOT
    Configuration for the IAM group policy attachment atom. All inputs live on
    this single object — both fields are required.

    Attaches a single managed policy to an IAM group (PCI DSS Req 7: grant
    permissions to groups, not individual users). This is a non-exclusive
    attachment: it manages only this one (group, policy) pair.
  EOT

  type = object({
    # Both required: there is no safe default for "which policy on which group".
    group      = string # the IAM group name to attach the policy to
    policy_arn = string # the ARN of the managed policy to attach
  })

  # no `default` here because all fields are required

  validation {
    condition     = length(var.config.group) > 0
    error_message = "config.group must be a non-empty string."
  }

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::(aws|[0-9]{12}):policy/", var.config.policy_arn))
    error_message = "config.policy_arn must be a valid IAM policy ARN (arn:aws:iam::<account|aws>:policy/...)."
  }
}
