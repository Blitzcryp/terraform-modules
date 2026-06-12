variable "config" {
  description = <<-EOT
    Configuration for ECS service Application Auto Scaling. All inputs live on
    this single object. Wraps an aws_appautoscaling_target plus two
    target-tracking aws_appautoscaling_policy resources (CPU and memory).

    Secure/sensible defaults are baked into the optional() fields: min_capacity
    defaults to 2 (>1 task for availability), scalable_dimension/service_namespace
    target an ECS service's DesiredCount. The caller only supplies the required
    `resource_id` (e.g. "service/<cluster>/<service>"). This atom takes the
    resource_id as an input and does NOT create the ECS service (dependencies
    flow down by reference).
  EOT

  type = object({
    # resource_id is REQUIRED: identifies the scalable ECS service, in the form
    # "service/<cluster-name>/<service-name>". The caller must decide it.
    resource_id = string

    # --- Capacity bounds (min defaults to 2 for availability) ---
    min_capacity = optional(number, 2)
    max_capacity = optional(number, 10)

    scalable_dimension = optional(string, "ecs:service:DesiredCount")
    service_namespace  = optional(string, "ecs")

    # --- Target-tracking targets (percent utilisation) ---
    target_cpu    = optional(number, 60)
    target_memory = optional(number, 70)

    scale_in_cooldown  = optional(number, 300) # slower scale-in to avoid flapping
    scale_out_cooldown = optional(number, 60)  # faster scale-out for responsiveness

    tags = optional(map(string), {})
  })
  # no `default` because `resource_id` is required

  validation {
    condition     = can(regex("^service/[^/]+/[^/]+$", var.config.resource_id))
    error_message = "config.resource_id must be of the form 'service/<cluster-name>/<service-name>'."
  }

  validation {
    condition     = var.config.min_capacity >= 1
    error_message = "config.min_capacity must be >= 1 (keep at least one task running)."
  }

  validation {
    condition     = var.config.max_capacity >= var.config.min_capacity
    error_message = "config.max_capacity must be >= config.min_capacity."
  }

  validation {
    condition     = var.config.target_cpu > 0 && var.config.target_cpu <= 100
    error_message = "config.target_cpu must be a percentage in the range (0, 100]."
  }

  validation {
    condition     = var.config.target_memory > 0 && var.config.target_memory <= 100
    error_message = "config.target_memory must be a percentage in the range (0, 100]."
  }
}
