variable "config" {
  description = <<-EOT
    Configuration for the Auto Scaling group. All inputs live on this single
    object. The caller supplies the required `name`, `launch_template_id`, and
    `vpc_zone_identifier` (the private subnets the ASG launches instances into).
    Sizing, health checks, and target-group attachment have sensible defaults.
    Tags are converted into ASG `tag {}` blocks with propagate_at_launch=true so
    launched instances inherit them (PCI DSS Req 1 traceability).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name                = string       # ASG name
    launch_template_id  = string       # the launch template to scale from
    vpc_zone_identifier = list(string) # private subnets across AZs

    # --- Launch template version ---
    launch_template_version = optional(string, "$Latest")

    # --- Sizing ---
    min_size         = optional(number, 2)
    max_size         = optional(number, 4)
    desired_capacity = optional(number, 2)

    # --- Health checks ---
    health_check_type         = optional(string, "EC2") # "EC2" or "ELB"
    health_check_grace_period = optional(number, 300)

    # --- Load balancer attachment ---
    target_group_arns = optional(list(string), [])

    tags = optional(map(string), {})
  })

  # no `default` here because name, launch_template_id and vpc_zone_identifier are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = length(var.config.vpc_zone_identifier) > 0
    error_message = "config.vpc_zone_identifier must list at least one subnet id."
  }

  validation {
    condition     = var.config.min_size >= 0 && var.config.max_size >= var.config.min_size
    error_message = "config.max_size must be >= config.min_size, and both must be non-negative."
  }

  validation {
    condition     = var.config.desired_capacity >= var.config.min_size && var.config.desired_capacity <= var.config.max_size
    error_message = "config.desired_capacity must be between config.min_size and config.max_size."
  }

  validation {
    condition     = contains(["EC2", "ELB"], var.config.health_check_type)
    error_message = "config.health_check_type must be EC2 or ELB."
  }
}
