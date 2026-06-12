variable "config" {
  description = <<-EOT
    Configuration for the Amazon Inspector v2 enabler. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so passing `{}` (or omitting config entirely) enables continuous
    vulnerability scanning for ECR, EC2 and Lambda in the current account
    (PCI DSS Req 6 & Req 11).
  EOT

  type = object({
    # PCI DSS Req 6/11: scan these resource types for vulnerabilities.
    resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])
    # Accounts to enable Inspector for. Empty = the current account.
    account_ids = optional(list(string), [])
  })

  default = {}

  validation {
    condition = length(var.config.resource_types) > 0 && alltrue([
      for t in var.config.resource_types :
      contains(["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"], t)
    ])
    error_message = "config.resource_types must be a non-empty subset of EC2, ECR, LAMBDA, LAMBDA_CODE."
  }
}
