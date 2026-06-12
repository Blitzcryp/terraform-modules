variable "config" {
  description = <<-EOT
    Configuration for the load balancer target group (aws_lb_target_group). All
    inputs live on this single object. PCI-DSS-compliant defaults are baked into
    the optional() fields, so passing only the required fields yields a target
    group that expects encrypted (HTTPS) traffic by default.
  EOT

  type = object({
    name   = string # required
    port   = number # required
    vpc_id = string # required

    # --- Secure-by-default controls (PCI DSS Req 4: encrypt transmission) ---
    protocol = optional(string, "HTTPS") # default to encrypted backend traffic

    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 300)

    # Health check expects HTTPS by default to match the secure protocol default.
    health_check = optional(object({
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTPS")
      matcher             = optional(string, "200")
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
    }), {})

    tags = optional(map(string), {})
  })

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.config.protocol)
    error_message = "config.protocol must be HTTP or HTTPS."
  }

  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.config.target_type)
    error_message = "config.target_type must be instance, ip, lambda, or alb."
  }

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.config.health_check.protocol)
    error_message = "config.health_check.protocol must be HTTP or HTTPS."
  }
}
