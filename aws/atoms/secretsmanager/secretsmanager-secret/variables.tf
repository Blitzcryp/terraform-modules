variable "config" {
  description = <<-EOT
    Configuration for the Secrets Manager secret atom. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields: the secret is encrypted with a customer-managed KMS key (Req 3) and
    deletion uses a 30-day recovery window. Insecure choices require flipping an
    explicit `allow_*` escape hatch.

    SECURITY: This module never sets the secret's value. The secret material is
    created/rotated out-of-band (a secrets source, a rotation Lambda, or manual
    population) — never in Terraform source control (PCI DSS Req 3.5 / Req 8).
  EOT

  type = object({
    # --- Required: the caller must decide the secret name. ---
    name = string

    description = optional(string, "Managed by terraform (atoms/secretsmanager/secretsmanager-secret)")

    # --- Encryption at rest (PCI DSS Req 3) ---
    # CMK ARN that encrypts the secret. When null the secret falls back to the
    # AWS-managed `aws/secretsmanager` key, which is less strict — that path is
    # gated behind the allow_aws_managed_key escape hatch.
    kms_key_arn = optional(string)

    # --- Deletion safety ---
    # 7-30 = recovery window (longer is safer); 0 = immediate, irreversible
    # deletion (gated behind allow_immediate_deletion).
    recovery_window_in_days = optional(number, 30)

    # --- Optional rotation (PCI DSS Req 8: rotate credentials) ---
    # When rotation_lambda_arn is set, a rotation schedule is created.
    rotation_lambda_arn = optional(string)
    rotation_days       = optional(number, 30)

    # --- Optional resource policy (JSON). null = no resource policy. ---
    policy = optional(string)

    # --- Tagging ---
    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    allow_aws_managed_key    = optional(bool, false) # permit kms_key_arn = null
    allow_immediate_deletion = optional(bool, false) # permit recovery_window_in_days = 0
  })

  # no `default` here because `name` is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.config.name))
    error_message = "config.name must be 1-512 chars of [a-zA-Z0-9/_+=.@-] (Secrets Manager naming rules)."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition     = var.config.recovery_window_in_days == 0 || (var.config.recovery_window_in_days >= 7 && var.config.recovery_window_in_days <= 30)
    error_message = "config.recovery_window_in_days must be 0 (immediate) or between 7 and 30."
  }

  validation {
    condition     = var.config.rotation_days >= 1 && var.config.rotation_days <= 1000
    error_message = "config.rotation_days must be between 1 and 1000."
  }

  validation {
    condition     = var.config.rotation_lambda_arn == null || can(regex("^arn:aws[a-zA-Z-]*:lambda:", var.config.rotation_lambda_arn))
    error_message = "config.rotation_lambda_arn, when set, must be a valid Lambda function ARN (arn:aws:lambda:...)."
  }
}
