locals {
  module_tags = {
    Module = "atoms/lambda/lambda-function" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  has_env = length(var.config.environment_variables) > 0
  has_vpc = length(var.config.vpc_subnet_ids) > 0
}

resource "aws_lambda_function" "this" {
  # checkov:skip=CKV_AWS_50: X-Ray Active tracing IS the enforced default. Checkov
  # cannot resolve enable_xray through the config object's optional() field, so it
  # does not see the always-present tracing_config block. Verified by the
  # "secure_defaults" assertion in tests/defaults.tftest.hcl (tracing mode == Active).
  # checkov:skip=CKV_AWS_272: Code-signing requires an AWS Signer signing profile,
  # an optional supply-chain control not modeled by this atom. Callers using signed
  # artifacts attach a code_signing_config out of band; no PCI requirement mandates it.
  function_name = var.config.function_name
  role          = var.config.role
  package_type  = var.config.package_type
  architectures = var.config.architectures

  # Zip packaging: runtime + handler + code source.
  runtime   = var.config.runtime
  handler   = var.config.handler
  filename  = var.config.filename
  s3_bucket = var.config.s3_bucket
  s3_key    = var.config.s3_key

  # Image packaging: ECR image URI.
  image_uri = var.config.image_uri

  memory_size                    = var.config.memory_size
  timeout                        = var.config.timeout
  reserved_concurrent_executions = var.config.reserved_concurrent_executions
  layers                         = var.config.layers

  # PCI DSS Req 3: encrypt environment variables at rest with a customer-managed
  # key when one is supplied. When env vars are set without a CMK the escape
  # hatch must be flipped (see precondition); Lambda then falls back to the
  # AWS-managed default key.
  kms_key_arn = var.config.kms_key_arn

  dynamic "environment" {
    for_each = local.has_env ? [1] : []
    content {
      variables = var.config.environment_variables
    }
  }

  # VPC attachment only when subnets are supplied.
  dynamic "vpc_config" {
    for_each = local.has_vpc ? [1] : []
    content {
      subnet_ids         = var.config.vpc_subnet_ids
      security_group_ids = var.config.vpc_security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.config.dead_letter_target_arn == null ? [] : [1]
    content {
      target_arn = var.config.dead_letter_target_arn
    }
  }

  # PCI DSS Req 10: X-Ray active tracing on by default for end-to-end traceability.
  tracing_config {
    mode = var.config.enable_xray ? "Active" : "PassThrough"
  }

  tags = local.tags

  lifecycle {
    # Encryption at rest of environment variables must be intentional to weaken
    # (PCI DSS Req 3). If env vars are set, a CMK is required unless the escape
    # hatch is flipped.
    precondition {
      condition     = !local.has_env || var.config.kms_key_arn != null || var.config.allow_unencrypted_env
      error_message = "environment_variables are set without config.kms_key_arn (no customer-managed key encrypting env vars at rest) and config.allow_unencrypted_env is not true. File a PCI exception (security@emag.ro) and set the flag, or supply a CMK."
    }
  }
}
