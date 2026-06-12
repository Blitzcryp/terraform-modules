variable "config" {
  description = <<-EOT
    Configuration for the Step Functions state machine. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so the caller only has to supply the required `name`, `definition`
    (the Amazon States Language JSON) and `role_arn`. Insecure choices require
    flipping an explicit `allow_*` escape hatch.

    OBSERVABILITY (PCI DSS Req 10): execution logging defaults to level ALL and
    X-Ray tracing is on. Logging requires a CloudWatch log destination; when no
    destination can be supplied, logging must be intentionally waived via the
    `allow_no_logging` escape hatch.

    SECURITY (PCI DSS Req 3): execution data is NOT logged by default
    (include_execution_data=false). Execution input/output may contain
    cardholder data (CHD); only enable include_execution_data for workflows you
    have confirmed never carry sensitive payloads.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string # state machine name
    definition = string # Amazon States Language (ASL) JSON definition
    role_arn   = string # execution role ARN (states.amazonaws.com assumes it)

    type = optional(string, "STANDARD") # STANDARD | EXPRESS

    # --- Observability (PCI DSS Req 10) ---
    # CloudWatch Logs destination ARN (log group). When null, logging cannot be
    # enabled and allow_no_logging must be set.
    log_destination_arn    = optional(string)
    log_level              = optional(string, "ALL") # ALL | ERROR | FATAL | OFF
    include_execution_data = optional(bool, false)   # PCI DSS Req 3: avoid logging CHD payloads
    enable_tracing         = optional(bool, true)    # X-Ray active tracing

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_no_logging = optional(bool, false) # permit running without a log destination
  })

  # no `default` here because name, definition and role_arn are required

  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.config.type)
    error_message = "config.type must be STANDARD or EXPRESS."
  }

  validation {
    condition     = contains(["ALL", "ERROR", "FATAL", "OFF"], var.config.log_level)
    error_message = "config.log_level must be ALL, ERROR, FATAL, or OFF."
  }

  validation {
    condition     = can(jsondecode(var.config.definition))
    error_message = "config.definition must be valid JSON (Amazon States Language)."
  }

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::", var.config.role_arn))
    error_message = "config.role_arn must be a valid IAM role ARN (arn:aws:iam::...)."
  }

  validation {
    condition     = var.config.log_destination_arn == null || can(regex("^arn:aws[a-z-]*:logs:", var.config.log_destination_arn))
    error_message = "config.log_destination_arn, when set, must be a valid CloudWatch Logs ARN (arn:aws:logs:...)."
  }
}
