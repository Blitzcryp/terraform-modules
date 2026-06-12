variable "config" {
  description = <<-EOT
    Configuration for the Lambda function atom. All inputs live on this single
    object. PCI-DSS-compliant defaults are baked into the optional() fields:
    environment variables are encrypted at rest with a CMK (Req 3), X-Ray active
    tracing is on (Req 10), and the function runs on arm64. Insecure choices
    (e.g. unencrypted env vars) require flipping an explicit `allow_*` escape
    hatch.

    SECURITY: never put secret values in environment_variables in plaintext.
    Store secrets in SSM Parameter Store / Secrets Manager and reference them at
    runtime (e.g. resolve them inside the handler, or via the
    `secretsmanager`/`ssm` extensions). environment_variables are encrypted at
    rest with the CMK but are still readable by anyone with lambda:GetFunction.
  EOT

  type = object({
    # --- Required: the caller must decide these ---
    function_name = string # unique function name
    role          = string # execution role ARN (PCI DSS Req 7/8)

    # --- Packaging ---
    package_type = optional(string, "Zip") # Zip | Image
    runtime      = optional(string)        # required for Zip (e.g. python3.12); unused for Image
    handler      = optional(string)        # required for Zip (e.g. index.handler); unused for Image
    filename     = optional(string)        # local deployment package (Zip)
    s3_bucket    = optional(string)        # S3 deployment package bucket (Zip)
    s3_key       = optional(string)        # S3 deployment package key (Zip)
    image_uri    = optional(string)        # ECR image URI (Image)
    layers       = optional(list(string), [])

    # --- Sizing / runtime ---
    memory_size                    = optional(number, 128)
    timeout                        = optional(number, 3)
    reserved_concurrent_executions = optional(number, -1) # -1 = unreserved
    architectures                  = optional(list(string), ["arm64"])

    # --- Environment (PCI DSS Req 3: encrypt env vars at rest) ---
    environment_variables = optional(map(string), {})
    kms_key_arn           = optional(string) # CMK encrypting env vars; required when env vars set unless allow_unencrypted_env=true

    # --- Networking (optional VPC attachment) ---
    vpc_subnet_ids         = optional(list(string), [])
    vpc_security_group_ids = optional(list(string), [])

    # --- Reliability ---
    dead_letter_target_arn = optional(string) # SQS/SNS ARN for failed async invocations

    # --- Observability (PCI DSS Req 10) ---
    enable_xray = optional(bool, true) # X-Ray active tracing

    tags = optional(map(string), {})

    # --- Escape hatches (insecure choices must be explicit & auditable) ---
    # Permit setting environment_variables without a CMK (env vars use the
    # AWS-managed default Lambda key instead of a customer-managed key).
    allow_unencrypted_env = optional(bool, false)
  })

  # no `default` here because function_name and role are required

  validation {
    condition     = contains(["Zip", "Image"], var.config.package_type)
    error_message = "config.package_type must be \"Zip\" or \"Image\"."
  }

  # Zip packages need a code source (local file, S3 object, or inline image is
  # not valid for Zip) and a runtime + handler.
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

  # Image packages need an image URI.
  validation {
    condition     = var.config.package_type != "Image" || var.config.image_uri != null
    error_message = "config.package_type=\"Image\" requires config.image_uri."
  }

  validation {
    condition     = var.config.memory_size >= 128 && var.config.memory_size <= 10240
    error_message = "config.memory_size must be between 128 and 10240 MB."
  }

  validation {
    condition     = var.config.timeout >= 1 && var.config.timeout <= 900
    error_message = "config.timeout must be between 1 and 900 seconds."
  }

  validation {
    condition = alltrue([
      for a in var.config.architectures : contains(["x86_64", "arm64"], a)
    ])
    error_message = "config.architectures entries must be \"x86_64\" or \"arm64\"."
  }

  validation {
    condition     = var.config.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.config.kms_key_arn))
    error_message = "config.kms_key_arn, when set, must be a valid KMS key ARN (arn:aws:kms:...)."
  }
}
