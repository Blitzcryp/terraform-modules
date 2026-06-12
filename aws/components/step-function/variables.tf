variable "config" {
  description = <<-EOT
    Configuration for the step-function component (a secure Step Functions
    workflow: execution IAM role + encrypted CloudWatch log group + customer-
    managed KMS key (created unless a BYO key is supplied) + the state machine
    itself). All inputs live on this single object.

    PCI-compliant defaults are baked into the optional() fields: execution
    logging defaults to level ALL and X-Ray active tracing is on (Req 10), the
    log group is encrypted at rest with a CMK and retained for one year
    (Req 3 / Req 10.5/10.7), and the execution role is least-privilege
    (CloudWatch Logs delivery + X-Ray only).

    SECURITY: execution data is NOT logged by default (include_execution_data=
    false). Step Functions execution input/output may carry cardholder data
    (CHD); only enable include_execution_data for workflows you have confirmed
    never carry sensitive payloads (PCI DSS Req 3).

    The execution role only knows how to log and trace. Grant the role the
    permissions the workflow needs to invoke downstream services (Lambda, SNS,
    ECS, etc.) via config.additional_policy_json — a least-privilege policy you
    supply (PCI DSS Req 7).
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    name       = string # state machine + role + log group base name
    definition = string # Amazon States Language (ASL) JSON definition

    type = optional(string, "STANDARD") # STANDARD | EXPRESS

    # --- Encryption (PCI DSS Req 3) ---
    # BYO CMK encrypting the execution log group. When null this component
    # creates a CMK whose key policy authorises CloudWatch Logs in this region.
    kms_key_arn = optional(string)

    # --- Observability (PCI DSS Req 10) ---
    log_level              = optional(string, "ALL") # ALL | ERROR | FATAL | OFF
    include_execution_data = optional(bool, false)   # PCI DSS Req 3: avoid logging CHD payloads
    log_retention_days     = optional(number, 365)

    # --- Authorisation (PCI DSS Req 7) ---
    # Least-privilege policy JSON granting the workflow the permissions it needs
    # to invoke downstream services. Attached to the execution role alongside the
    # built-in CloudWatch Logs + X-Ray policy.
    additional_policy_json = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` because name and definition are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,80}$", var.config.name))
    error_message = "config.name must be 1-80 chars of letters, numbers, hyphens, or underscores."
  }

  validation {
    condition     = can(jsondecode(var.config.definition))
    error_message = "config.definition must be valid JSON (Amazon States Language)."
  }

  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.config.type)
    error_message = "config.type must be STANDARD or EXPRESS."
  }

  validation {
    condition     = contains(["ALL", "ERROR", "FATAL", "OFF"], var.config.log_level)
    error_message = "config.log_level must be ALL, ERROR, FATAL, or OFF."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = var.config.additional_policy_json == null || can(jsondecode(var.config.additional_policy_json))
    error_message = "config.additional_policy_json, when set, must be valid JSON."
  }
}
