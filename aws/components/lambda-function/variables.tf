variable "config" {
  description = <<-EOT
    Configuration for the lambda-function component (a secure serverless function:
    execution IAM role + encrypted CloudWatch log group + customer-managed KMS key
    (created unless a BYO key is supplied) + optional dedicated VPC security group
    + the Lambda function itself). All inputs live on this single object.

    PCI-compliant defaults are baked into the optional() fields: environment
    variables and logs are encrypted at rest with a CMK (Req 3), X-Ray active
    tracing is on (Req 10), logs are retained for one year (Req 10.5/10.7), the
    execution role is least-privilege (CloudWatch Logs only, plus EC2 ENI perms
    only when a VPC is attached), and the function runs on arm64.

    SECURITY: never put secret values in environment_variables in plaintext.
    Store secrets in SSM Parameter Store / Secrets Manager and reference them at
    runtime (PCI DSS Req 3 / Req 8). env vars are encrypted at rest with the CMK
    but are still readable by anyone with lambda:GetFunction.
  EOT

  type = object({
    # --- Required: the caller must decide this ---
    name = string # function + role + SG + log group base name

    # --- Packaging ---
    package_type = optional(string, "Zip") # Zip | Image
    runtime      = optional(string)        # required for Zip (e.g. python3.12)
    handler      = optional(string)        # required for Zip (e.g. index.handler)
    filename     = optional(string)        # local deployment package (Zip)
    s3_bucket    = optional(string)        # S3 deployment package bucket (Zip)
    s3_key       = optional(string)        # S3 deployment package key (Zip)
    image_uri    = optional(string)        # ECR image URI (Image)
    layers       = optional(list(string), [])

    # --- Sizing / runtime ---
    memory_size                    = optional(number, 128)
    timeout                        = optional(number, 30)
    reserved_concurrent_executions = optional(number, -1)
    architectures                  = optional(list(string), ["arm64"])

    # --- Environment (PCI DSS Req 3) ---
    environment_variables = optional(map(string), {})

    # --- Encryption (PCI DSS Req 3) ---
    # BYO CMK encrypting env vars + logs. When null this component creates a CMK
    # whose key policy authorises CloudWatch Logs in this region.
    kms_key_arn = optional(string)

    # --- Reliability ---
    dead_letter_target_arn = optional(string)

    # --- Observability (PCI DSS Req 10) ---
    enable_xray        = optional(bool, true)
    log_retention_days = optional(number, 365)

    # --- Networking (optional VPC attachment) ---
    # When vpc_subnet_ids is set the component creates a dedicated security group
    # and attaches the function to the VPC; the execution role also gains the EC2
    # ENI permissions Lambda needs for VPC access.
    vpc_id         = optional(string) # required when vpc_subnet_ids is set (for the SG)
    vpc_subnet_ids = optional(list(string), [])

    # Egress rules for the function's security group. Defaults to HTTPS-only
    # outbound (AWS APIs, Secrets Manager, etc.) — documented per PCI DSS Req 1.
    egress_rules = optional(list(object({
      description                  = string
      ip_protocol                  = string
      from_port                    = optional(number)
      to_port                      = optional(number)
      cidr_ipv4                    = optional(string)
      cidr_ipv6                    = optional(string)
      referenced_security_group_id = optional(string)
      prefix_list_id               = optional(string)
    })), [])

    tags = optional(map(string), {})
  })

  # no `default` because `name` is required

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,140}$", var.config.name))
    error_message = "config.name must be 1-140 chars of letters, numbers, hyphens, or underscores."
  }

  validation {
    condition     = contains(["Zip", "Image"], var.config.package_type)
    error_message = "config.package_type must be \"Zip\" or \"Image\"."
  }

  validation {
    condition = var.config.package_type != "Zip" || (
      var.config.filename != null ||
      (var.config.s3_bucket != null && var.config.s3_key != null)
    )
    error_message = "config.package_type=\"Zip\" requires a code source: set config.filename, or both config.s3_bucket and config.s3_key."
  }

  validation {
    condition     = var.config.package_type != "Zip" || (var.config.runtime != null && var.config.handler != null)
    error_message = "config.package_type=\"Zip\" requires config.runtime and config.handler."
  }

  validation {
    condition     = var.config.package_type != "Image" || var.config.image_uri != null
    error_message = "config.package_type=\"Image\" requires config.image_uri."
  }

  # A VPC attachment needs a vpc_id to place the dedicated security group in.
  validation {
    condition     = length(var.config.vpc_subnet_ids) == 0 || var.config.vpc_id != null
    error_message = "config.vpc_id is required when config.vpc_subnet_ids is set (the security group needs a VPC)."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
