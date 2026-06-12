variable "config" {
  description = <<-EOT
    Configuration for the AWS Config configuration recorder + delivery channel +
    recorder status. All inputs live on this single object. This atom records
    resource configuration changes (PCI DSS Req 10) to a pre-existing S3 bucket
    using a pre-existing IAM role; it does NOT create the bucket or the role
    (an atom owns one logical resource group and takes dependencies by reference).
    PCI-compliant defaults are baked into the optional() fields.
  EOT

  type = object({
    # Recorder name (also used for the delivery channel and recorder status).
    name = string

    # Delivery target S3 bucket name. Taken as input — NOT created by this atom.
    s3_bucket_name = string

    # ARN of the AWS Config service role. Taken as input — NOT created here.
    iam_role_arn = string

    # --- Secure-by-default controls (PCI DSS Req 10: record everything) ---
    record_all_resources          = optional(bool, true)
    include_global_resource_types = optional(bool, true)

    # Optional SNS topic for configuration change / compliance notifications.
    sns_topic_arn = optional(string)

    # Kept for interface uniformity. NOTE: the AWS Config recorder / delivery
    # channel / recorder-status resources do not accept tags; this is surfaced
    # in the manifest but not applied to a resource.
    tags = optional(map(string), {})
  })

  # no `default` here because name, s3_bucket_name and iam_role_arn are required

  validation {
    condition     = length(var.config.name) > 0
    error_message = "config.name must be a non-empty string."
  }

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::", var.config.iam_role_arn))
    error_message = "config.iam_role_arn must be a valid IAM role ARN (arn:aws:iam::...)."
  }

  validation {
    condition     = var.config.sns_topic_arn == null || can(regex("^arn:aws[a-zA-Z-]*:sns:", var.config.sns_topic_arn))
    error_message = "config.sns_topic_arn, when set, must be a valid SNS topic ARN (arn:aws:sns:...)."
  }
}
