variable "config" {
  description = <<-EOT
    Configuration for the Amazon GuardDuty detector. All inputs live on this
    single object. PCI-DSS-compliant defaults are baked into the optional()
    fields, so passing `{}` (or omitting config entirely) enables GuardDuty
    threat detection with the fastest finding cadence and S3 + malware
    protection on (PCI DSS Req 10/11 continuous monitoring). Protection
    features are configured via aws_guardduty_detector_feature resources.
  EOT

  type = object({
    enable                       = optional(bool, true)
    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")

    # Protection features (each maps to an aws_guardduty_detector_feature).
    enable_s3_protection         = optional(bool, true)
    enable_kubernetes_protection = optional(bool, false)
    enable_malware_protection    = optional(bool, true)

    # Kept for interface uniformity. NOTE: aws_guardduty_detector_feature does
    # not accept tags; tags are applied to the detector itself.
    tags = optional(map(string), {})
  })

  default = {}

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.config.finding_publishing_frequency)
    error_message = "config.finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}
