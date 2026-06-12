variable "config" {
  description = <<-EOT
    Configuration for the VPC. All inputs live on this single object.
    PCI-DSS-compliant defaults are baked into the optional() fields. Required
    fields (name, cidr_block) have no default, so config cannot be omitted.
    Insecure choices require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name       = string # required — no default
    cidr_block = string # required — no default

    instance_tenancy = optional(string, "default")

    # --- Secure-by-default controls (PCI DSS Req 1 segmentation, Req 10 logging) ---
    enable_dns_support        = optional(bool, true)
    enable_dns_hostnames      = optional(bool, true)
    enable_flow_logs          = optional(bool, true) # PCI DSS Req 10
    flow_log_traffic_type     = optional(string, "ALL")
    flow_log_destination_type = optional(string, "cloud-watch-logs")
    flow_log_destination_arn  = optional(string) # null = none; required when enable_flow_logs
    flow_log_iam_role_arn     = optional(string) # null = none; required for cloud-watch-logs delivery
    tags                      = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_flow_logs_disabled = optional(bool, false)
  })

  # no `default` here because name and cidr_block are required

  validation {
    condition     = can(cidrhost(var.config.cidr_block, 0))
    error_message = "config.cidr_block must be a valid IPv4 CIDR (e.g. 10.0.0.0/16)."
  }

  validation {
    condition     = contains(["default", "dedicated"], var.config.instance_tenancy)
    error_message = "config.instance_tenancy must be 'default' or 'dedicated'."
  }

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.config.flow_log_traffic_type)
    error_message = "config.flow_log_traffic_type must be ACCEPT, REJECT, or ALL."
  }

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.config.flow_log_destination_type)
    error_message = "config.flow_log_destination_type must be 'cloud-watch-logs' or 's3'."
  }
}
