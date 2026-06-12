variable "config" {
  description = <<-EOT
    Configuration for the inspector component (account-level vulnerability
    scanning plus a findings-notification SNS topic). All inputs live on this
    single object. PCI-compliant defaults are baked into the optional() fields,
    so passing `{}` (or omitting config) enables continuous Inspector v2 scanning
    for ECR, EC2 and Lambda (Req 6 & 11) and creates a CMK-encrypted SNS topic
    (Req 3 & 4) for findings notifications.

    NOTE: routing Inspector findings to the SNS topic requires an EventBridge
    rule. There is no EventBridge atom in this library yet, so this component
    only EXPOSES the topic ARN in its manifest; a future EventBridge component
    must wire Inspector findings -> this topic. No raw resources are added here.
  EOT

  type = object({
    # PCI DSS Req 6/11: resource types Inspector scans for vulnerabilities.
    resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])

    # --- Secure-by-default controls (PCI DSS Req 3 encryption) ---
    # BYO CMK for the SNS topic. null = this component creates one.
    kms_key_arn = optional(string)
    # Whether to create the findings-notification SNS topic.
    create_notification_topic = optional(bool, true)

    tags = optional(map(string), {})
  })

  default = {}

  validation {
    condition = length(var.config.resource_types) > 0 && alltrue([
      for t in var.config.resource_types :
      contains(["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"], t)
    ])
    error_message = "config.resource_types must be a non-empty subset of EC2, ECR, LAMBDA, LAMBDA_CODE."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
