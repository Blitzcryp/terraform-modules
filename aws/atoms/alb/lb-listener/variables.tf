variable "config" {
  description = <<-EOT
    Configuration for the load balancer listener (aws_lb_listener). All inputs
    live on this single object. PCI-DSS-compliant defaults are baked into the
    optional() fields: the listener terminates TLS (HTTPS) with a modern TLS1.2+
    policy by default. A plain-HTTP listener is only permitted via an explicit
    escape hatch, unless its sole purpose is to redirect to HTTPS.
  EOT

  type = object({
    load_balancer_arn = string # required
    port              = number # required

    # --- Secure-by-default controls (PCI DSS Req 4: encrypt transmission) ---
    protocol        = optional(string, "HTTPS")
    certificate_arn = optional(string)                                        # required when protocol = HTTPS
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06") # TLS1.2+ floor

    default_action = optional(object({
      type             = optional(string, "forward")
      target_group_arn = optional(string)
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
      }))
    }), {})

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_insecure_http = optional(bool, false) # permits a non-redirect plain-HTTP listener
  })

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.config.protocol)
    error_message = "config.protocol must be HTTP or HTTPS."
  }

  validation {
    condition     = contains(["forward", "redirect"], var.config.default_action.type)
    error_message = "config.default_action.type must be forward or redirect."
  }

  validation {
    condition     = var.config.protocol != "HTTPS" || var.config.certificate_arn != null
    error_message = "config.certificate_arn is required when config.protocol = HTTPS (PCI DSS Req 4)."
  }

  validation {
    condition     = var.config.default_action.type != "forward" || var.config.default_action.target_group_arn != null
    error_message = "config.default_action.target_group_arn is required when default_action.type = forward."
  }

  validation {
    condition     = var.config.default_action.type != "redirect" || var.config.default_action.redirect != null
    error_message = "config.default_action.redirect is required when default_action.type = redirect."
  }
}
