variable "config" {
  description = <<-EOT
    Configuration for the ecs-service component (a Fargate ECS service: task
    definition + service + dedicated security group + encrypted app log group +
    target-tracking autoscaling, optionally wired to a load balancer target
    group). All inputs live on this single object.

    PCI-compliant defaults are baked into the optional() fields: private
    networking (no public IP), deployment circuit-breaker rollback (atom
    default), encrypted CloudWatch logs, an SG with no public ingress, and
    autoscaling on between 2 and 10 tasks. Insecure choices require flipping an
    explicit `allow_*` escape hatch that is passed down to the underlying atoms.

    SECURITY: inject secrets into containers via the `secrets` block in
    container_definitions (Secrets Manager / SSM), never plaintext `environment`
    (PCI DSS Req 3 / Req 8).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name        = string       # service + task family + SG + log group base name
    cluster_arn = string       # ARN of the ECS cluster this service runs on
    vpc_id      = string       # VPC for the service security group
    subnet_ids  = list(string) # private subnets for the task ENIs

    # JSON string describing the containers (see SECURITY note above).
    container_definitions = string

    # --- Task sizing / runtime ---
    cpu                = optional(string, "256")
    memory             = optional(string, "512")
    desired_count      = optional(number, 2) # >1 for availability
    execution_role_arn = optional(string)
    task_role_arn      = optional(string)

    # --- Encryption (PCI DSS Req 3) ---
    kms_key_arn = optional(string) # CMK for the app log group; null is rejected unless allow_unencrypted_logs=true

    log_retention_days = optional(number, 365)

    # --- Networking (PCI DSS Req 1) ---
    # No public IP on task ENIs by default — tasks stay in private subnets.
    assign_public_ip = optional(bool, false)

    # Ingress rules for the service security group. Empty by default (no
    # ingress); typically a single rule referencing the load balancer's SG.
    ingress_rules = optional(list(object({
      description                  = string
      ip_protocol                  = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      referenced_security_group_id = optional(string)
      prefix_list_id               = optional(string)
    })), [])

    # --- Load balancing (optional) ---
    # When target_group_arn is set the service registers with that target group;
    # container_name + container_port then identify the load-balanced container.
    target_group_arn = optional(string)
    container_name   = optional(string)
    container_port   = optional(number)

    # --- Autoscaling (target tracking) ---
    enable_autoscaling = optional(bool, true)
    min_capacity       = optional(number, 2)
    max_capacity       = optional(number, 10)
    target_cpu         = optional(number, 60)
    target_memory      = optional(number, 70)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Assign a public IP to task ENIs (exposes tasks directly to the internet).
    allow_public_ip = optional(bool, false)
    # Run the app log group without a CMK (passed to the log-group atom).
    allow_unencrypted_logs = optional(bool, false)
  })
  # no `default` because several fields are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.config.name))
    error_message = "config.name must be 1-255 chars of letters, numbers, hyphens, or underscores."
  }

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:ecs:[^:]+:[0-9]+:cluster/.+$", var.config.cluster_arn))
    error_message = "config.cluster_arn must be a valid ECS cluster ARN (arn:aws:ecs:<region>:<account>:cluster/<name>)."
  }

  validation {
    condition     = length(var.config.subnet_ids) > 0
    error_message = "config.subnet_ids must contain at least one subnet."
  }

  validation {
    condition     = can(jsondecode(var.config.container_definitions))
    error_message = "config.container_definitions must be a valid JSON string."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  # If load-balanced, the container name + port must be supplied so the service
  # knows which container to register with the target group.
  validation {
    condition     = var.config.target_group_arn == null || (var.config.container_name != null && var.config.container_port != null)
    error_message = "When config.target_group_arn is set you must also set config.container_name and config.container_port."
  }
}
