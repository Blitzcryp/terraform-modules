variable "config" {
  description = <<-EOT
    Configuration for the ECS service. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields: tasks get
    NO public IP, deployment circuit breaker + rollback are on, and ECS Exec
    (a debugging backdoor into running containers) is off. Insecure choices
    require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name               = string       # required — service name
    cluster_arn        = string       # required — ARN of the ECS cluster (input)
    task_definition    = string       # required — task definition ARN or family:revision
    subnet_ids         = list(string) # required — subnets for the task ENIs
    security_group_ids = list(string) # required — security groups for the task ENIs

    desired_count = optional(number, 2) # >1 for availability
    launch_type   = optional(string, "FARGATE")

    # --- Secure-by-default controls ---
    # No public IP on task ENIs — tasks stay in private subnets (PCI DSS Req 1).
    assign_public_ip = optional(bool, false)

    # ECS Exec is an interactive shell into running containers — a debugging
    # backdoor. Off by default (PCI DSS Req 7: least privilege / restrict access).
    enable_execute_command = optional(bool, false)

    load_balancers = optional(list(object({
      target_group_arn = string
      container_name   = string
      container_port   = number
    })), [])

    # ECS rolling deployments with automatic rollback on failed health checks.
    deployment_controller_type        = optional(string, "ECS")
    health_check_grace_period_seconds = optional(number)

    propagate_tags = optional(string, "SERVICE")

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Assign a public IP to task ENIs (exposes tasks directly to the internet).
    allow_public_ip = optional(bool, false)
    # Enable ECS Exec interactive container access (debugging backdoor).
    allow_execute_command = optional(bool, false)
  })
  # no `default` because several fields are required

  validation {
    condition     = contains(["ECS", "CODE_DEPLOY", "EXTERNAL"], var.config.deployment_controller_type)
    error_message = "config.deployment_controller_type must be one of ECS, CODE_DEPLOY, EXTERNAL."
  }

  validation {
    condition     = var.config.desired_count >= 0
    error_message = "config.desired_count must be >= 0."
  }
}
