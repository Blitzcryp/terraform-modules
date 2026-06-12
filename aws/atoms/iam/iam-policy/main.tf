locals {
  module_tags = {
    Module = "atoms/iam/iam-policy" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # PCI DSS Req 7 guardrail: flag a policy that grants full admin (Action "*"
  # on Resource "*"). Pragmatic string check: re-serialise the policy JSON to a
  # canonical compact form via jsonencode(jsondecode(...)) so spacing/key-order
  # differences don't defeat the match, then look for the "*" action and "*"
  # resource tokens.
  canonical_policy = jsonencode(jsondecode(var.config.policy))
  grants_admin = (
    can(regex("\"Action\":\"\\*\"", local.canonical_policy)) &&
    can(regex("\"Resource\":\"\\*\"", local.canonical_policy))
  )
}

resource "aws_iam_policy" "this" {
  name        = var.config.name
  description = var.config.description
  path        = var.config.path
  policy      = var.config.policy

  tags = local.tags

  # Least privilege must be intentional to abandon (PCI DSS Req 7). Reject a
  # policy granting full admin ("*" on "*") unless allow_admin_policy=true.
  lifecycle {
    precondition {
      condition     = !local.grants_admin || var.config.allow_admin_policy
      error_message = "Policy grants full admin (Action \"*\" on Resource \"*\") without config.allow_admin_policy=true. This violates PCI DSS Req 7 (least privilege). File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}
