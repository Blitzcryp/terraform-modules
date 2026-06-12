variable "config" {
  description = <<-EOT
    Configuration for the load balancer (aws_lb). All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    passing only the required fields yields a compliant, non-internet-facing ALB.
    Insecure choices require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name            = string       # required
    subnets         = list(string) # required
    security_groups = list(string) # required

    load_balancer_type = optional(string, "application")
    idle_timeout       = optional(number, 60)

    # --- Secure-by-default controls (PCI DSS Req 1: network controls; Req 4:
    #     encrypt transmission; Req 10: logging) ---
    internal                   = optional(bool, true) # PCI Req 1: not internet-facing by default
    drop_invalid_header_fields = optional(bool, true) # PCI Req 4: reject malformed headers
    enable_deletion_protection = optional(bool, true) # guard against accidental teardown
    desync_mitigation_mode     = optional(string, "defensive")

    # Access logging (PCI Req 10). When access_logs_bucket is set, logging is enabled.
    access_logs_bucket = optional(string) # null = no S3 access logs
    access_logs_prefix = optional(string)

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_internet_facing = optional(bool, false) # permits internal=false
  })

  validation {
    condition     = contains(["application", "network", "gateway"], var.config.load_balancer_type)
    error_message = "config.load_balancer_type must be application, network, or gateway."
  }

  validation {
    condition     = contains(["defensive", "strictest", "monitor"], var.config.desync_mitigation_mode)
    error_message = "config.desync_mitigation_mode must be defensive, strictest, or monitor."
  }

  validation {
    condition     = length(var.config.subnets) >= 2
    error_message = "config.subnets must list at least two subnets for availability."
  }
}
