variable "config" {
  description = <<-EOT
    Configuration for the IAM role. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields, so the
    caller only has to supply the required `assume_role_policy` (who may assume
    the role). Insecure choices require flipping an explicit `allow_*` escape
    hatch.
  EOT

  type = object({
    # assume_role_policy is REQUIRED: the caller MUST declare who can assume the
    # role (PCI DSS Req 7 least privilege, Req 8 identify & authenticate). No
    # safe default exists for "who can become this identity".
    assume_role_policy = string

    name        = optional(string) # if null, derived from name_prefix
    name_prefix = optional(string) # unique name beginning with this prefix; conflicts with name
    description = optional(string, "Managed by terraform (atoms/iam-role)")
    path        = optional(string, "/")

    # --- Secure-by-default controls (PCI DSS Req 7 / Req 8) ---
    permissions_boundary  = optional(string)           # cap the role's maximum effective permissions
    max_session_duration  = optional(number, 3600)     # 3600-43200; limits credential exposure window
    force_detach_policies = optional(bool, true)       # avoid orphaned dangling attachments
    managed_policy_arns   = optional(list(string), []) # managed policy ARNs to attach
    inline_policies       = optional(map(string), {})  # inline policy name => policy JSON
    tags                  = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_admin_policy = optional(bool, false)
  })

  # no `default` here because assume_role_policy is required

  validation {
    condition     = can(jsondecode(var.config.assume_role_policy))
    error_message = "config.assume_role_policy must be valid JSON."
  }

  validation {
    condition     = var.config.max_session_duration >= 3600 && var.config.max_session_duration <= 43200
    error_message = "config.max_session_duration must be between 3600 (1h) and 43200 (12h) seconds."
  }

  validation {
    condition     = alltrue([for p in values(var.config.inline_policies) : can(jsondecode(p))])
    error_message = "Each config.inline_policies value must be valid JSON."
  }
}
