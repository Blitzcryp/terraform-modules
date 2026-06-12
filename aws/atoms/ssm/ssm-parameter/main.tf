locals {
  module_tags = {
    Module = "atoms/ssm/ssm-parameter" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  is_secure = var.config.type == "SecureString"

  # A SecureString uses the supplied CMK via key_id; plaintext types pass null.
  key_id = local.is_secure ? var.config.kms_key_arn : null
}

resource "aws_ssm_parameter" "this" {
  name        = var.config.name
  type        = var.config.type
  value       = var.config.value # SECURITY: supplied out-of-band, never hardcoded (PCI DSS Req 3 / Req 8)
  key_id      = local.key_id
  description = var.config.description
  tier        = var.config.tier

  tags = local.tags

  lifecycle {
    # Plaintext (String/StringList) must be intentional to enable (PCI DSS Req 3 / Req 8).
    precondition {
      condition     = local.is_secure || var.config.allow_plaintext
      error_message = "Parameter type is not SecureString. Use type=SecureString with a CMK, or set config.allow_plaintext=true to store plaintext. File a PCI exception (security@emag.ro)."
    }
  }
}
