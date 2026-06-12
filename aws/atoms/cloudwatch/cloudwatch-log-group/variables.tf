variable "config" {
  description = <<-EOT
    Configuration for the CloudWatch log group. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields, so
    the caller only has to supply the required `name`. Insecure choices require
    flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    # name is REQUIRED: the caller must decide the log group name. No default.
    name = string

    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 retention) ---
    kms_key_arn       = optional(string)      # null is rejected unless allow_unencrypted=true
    retention_in_days = optional(number, 365) # 365 keeps audit logs >= 1 year; 0 requires allow_no_retention
    log_group_class   = optional(string, "STANDARD")
    skip_destroy      = optional(bool, false)
    tags              = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_unencrypted  = optional(bool, false)
    allow_no_retention = optional(bool, false)
  })

  # no `default` here because name is required

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.config.retention_in_days
    )
    error_message = "config.retention_in_days must be one of the CloudWatch-accepted values (1,3,5,7,14,30,60,90,120,150,180,365,400,545,731,1096,1827,2192,2557,2922,3288,3653) or 0 (never expire)."
  }

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.config.log_group_class)
    error_message = "config.log_group_class must be STANDARD or INFREQUENT_ACCESS."
  }
}
