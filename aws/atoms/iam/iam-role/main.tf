locals {
  module_tags = {
    Module = "atoms/iam/iam-role" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # PCI DSS Req 7 guardrail: flag any inline policy that grants full admin
  # (Action "*" on Resource "*"). Pragmatic string check: re-serialise each
  # policy JSON to a canonical compact form via jsonencode(jsondecode(...)) so
  # spacing/key-order differences don't defeat the match, then look for the "*"
  # action and "*" resource tokens.
  admin_inline_policies = [
    for name, policy in var.config.inline_policies : name
    if can(jsondecode(policy)) &&
    can(regex("\"Action\":\"\\*\"", jsonencode(jsondecode(policy)))) &&
    can(regex("\"Resource\":\"\\*\"", jsonencode(jsondecode(policy))))
  ]
}

resource "aws_iam_role" "this" {
  name                  = var.config.name
  name_prefix           = var.config.name_prefix
  description           = var.config.description
  path                  = var.config.path
  assume_role_policy    = var.config.assume_role_policy
  permissions_boundary  = var.config.permissions_boundary
  max_session_duration  = var.config.max_session_duration
  force_detach_policies = var.config.force_detach_policies

  tags = local.tags

  # Least privilege must be intentional to abandon (PCI DSS Req 7). Reject inline
  # policies granting full admin ("*" on "*") unless allow_admin_policy=true.
  lifecycle {
    precondition {
      condition     = length(local.admin_inline_policies) == 0 || var.config.allow_admin_policy
      error_message = "Inline policy grants full admin (Action \"*\" on Resource \"*\") without config.allow_admin_policy=true. This violates PCI DSS Req 7 (least privilege). File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Inline policies embedded in the role (managed via the dedicated resource so
# each policy has its own lifecycle and clean drift detection).
resource "aws_iam_role_policy" "this" {
  for_each = var.config.inline_policies
  name     = each.key
  role     = aws_iam_role.this.id
  policy   = each.value
}

# Managed-policy attachments (dedicated resource — non-exclusive, avoids the
# all-or-nothing behaviour of the role's managed_policy_arns argument).
resource "aws_iam_role_policy_attachment" "this" {
  for_each   = toset(var.config.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}
