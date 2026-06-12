locals {
  module_tags = {
    Module = "atoms/efs/efs-file-system" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # Attach a file-system policy only when TLS is enforced or extra statements are
  # supplied. The deny-non-TLS statement implements encryption in transit (Req 4).
  deny_non_tls_statement = {
    Sid       = "DenyNonTLSAccess"
    Effect    = "Deny"
    Principal = { AWS = "*" }
    Action    = "*"
    Resource  = aws_efs_file_system.this.arn
    Condition = { Bool = { "aws:SecureTransport" = "false" } }
  }

  policy_statements = concat(
    var.config.enforce_tls ? [local.deny_non_tls_statement] : [],
    var.config.additional_policy_statements,
  )
  attach_policy = length(local.policy_statements) > 0
}

resource "aws_efs_file_system" "this" {
  creation_token = var.config.name

  encrypted  = var.config.encrypted
  kms_key_id = var.config.encrypted ? var.config.kms_key_arn : null

  performance_mode                = var.config.performance_mode
  throughput_mode                 = var.config.throughput_mode
  provisioned_throughput_in_mibps = var.config.throughput_mode == "provisioned" ? var.config.provisioned_throughput_in_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.config.transition_to_ia == null ? [] : [var.config.transition_to_ia]
    content {
      transition_to_ia = lifecycle_policy.value
    }
  }

  tags = merge(local.tags, { Name = var.config.name })

  # Encryption at rest must be intentional to weaken (PCI DSS Req 3).
  lifecycle {
    precondition {
      condition     = var.config.encrypted || var.config.allow_unencrypted
      error_message = "Encryption at rest disabled without config.allow_unencrypted=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Tightly-coupled sub-resource: enforces TLS-only access (PCI DSS Req 4). It is
# meaningless without the file system it targets, so the atom owns it directly.
resource "aws_efs_file_system_policy" "this" {
  count = local.attach_policy ? 1 : 0

  file_system_id = aws_efs_file_system.this.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.policy_statements
  })
}
