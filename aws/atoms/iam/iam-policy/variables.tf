variable "config" {
  description = <<-EOT
    Configuration for the IAM managed policy. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    the caller only has to supply the required `name` and `policy` document.
    Insecure choices require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    # name is REQUIRED: the caller must decide the policy's identity.
    name = string
    # policy is REQUIRED: the policy document (JSON string). No safe default
    # exists for "what permissions does this grant" (PCI DSS Req 7).
    policy = string

    description = optional(string, "Managed by terraform (atoms/iam-policy)")
    path        = optional(string, "/")
    tags        = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_admin_policy = optional(bool, false)
  })

  # no `default` here because name and policy are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = can(jsondecode(var.config.policy))
    error_message = "config.policy must be valid JSON."
  }
}
