variable "config" {
  description = <<-EOT
    Configuration for the ECS task definition. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields
    (awsvpc networking, Fargate compatibility).

    SECURITY: Secrets (DB passwords, API keys, tokens) MUST be injected into
    containers via the `secrets` block inside `container_definitions`, sourced
    from AWS Secrets Manager or SSM Parameter Store — NEVER as plaintext in the
    `environment` block. Plaintext secrets in a task definition violate
    PCI DSS Req 3 (protect stored data) and Req 8 (authentication/credentials).
  EOT

  type = object({
    family = string # required — task definition family name

    # Required JSON string describing the containers. Inject secrets via the
    # `secrets` block (Secrets Manager / SSM), never plaintext `environment`
    # (PCI DSS Req 3 / Req 8 — see variable description).
    container_definitions = string

    # --- Secure / sensible defaults ---
    cpu                      = optional(string, "256")
    memory                   = optional(string, "512")
    network_mode             = optional(string, "awsvpc")          # task-level ENI isolation
    requires_compatibilities = optional(list(string), ["FARGATE"]) # managed, patched runtime

    # IAM roles are inputs (this atom does not create them — flow down by reference).
    execution_role_arn = optional(string)
    task_role_arn      = optional(string)

    volumes = optional(list(any), [])

    runtime_platform = optional(object({
      operating_system_family = optional(string, "LINUX")
      cpu_architecture        = optional(string, "X86_64")
    }))

    tags = optional(map(string), {})
  })
  # no `default` because `family` and `container_definitions` are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.config.family))
    error_message = "config.family must be 1-255 chars of letters, numbers, hyphens, or underscores."
  }

  validation {
    condition     = contains(["awsvpc", "bridge", "host", "none"], var.config.network_mode)
    error_message = "config.network_mode must be one of awsvpc, bridge, host, none."
  }

  validation {
    condition     = can(jsondecode(var.config.container_definitions))
    error_message = "config.container_definitions must be a valid JSON string."
  }
}
