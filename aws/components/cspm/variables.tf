variable "config" {
  description = <<-EOT
    Configuration for the CSPM (Cloud Security Posture Management) baseline
    component. All inputs live on this single object. This component bundles the
    four AWS-native posture services — Security Hub, AWS Config, GuardDuty and
    Inspector v2 — plus the supporting AWS Config delivery S3 bucket, KMS CMK and
    IAM service role. PCI-compliant defaults are baked into the optional() fields,
    so the caller only has to supply `name_prefix`; every capability is on by
    default and individually gated by its `enable_*` flag (PCI DSS Req 6/10/11).
  EOT

  type = object({
    # name_prefix is REQUIRED: base name for the Config bucket, KMS alias, IAM
    # role, recorder and channel. The caller must decide it. No default.
    name_prefix = string

    # BYO CMK: if set, no kms-key atom is created and this key encrypts the
    # Config delivery bucket. Otherwise the component owns a compliant CMK.
    kms_key_arn = optional(string)

    # --- Capability toggles (each gates the corresponding atom via count) ------
    enable_security_hub = optional(bool, true)
    enable_config       = optional(bool, true)
    enable_guardduty    = optional(bool, true)
    enable_inspector    = optional(bool, true)

    # Inspector v2 resource types to scan continuously (PCI DSS Req 6/11).
    inspector_resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])

    tags = optional(map(string), {})
  })

  # no `default` here because name_prefix is required

  validation {
    condition     = length(var.config.name_prefix) > 0
    error_message = "config.name_prefix must be a non-empty string."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-zA-Z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }

  validation {
    condition = length(var.config.inspector_resource_types) > 0 && alltrue([
      for t in var.config.inspector_resource_types :
      contains(["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"], t)
    ])
    error_message = "config.inspector_resource_types must be a non-empty subset of EC2, ECR, LAMBDA, LAMBDA_CODE."
  }
}
