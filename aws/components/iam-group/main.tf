locals {
  module_tags = {
    Module = "components/iam-group" # only hardcoded tag; global tags come from provider default_tags
  }
  # NOTE: none of the composed atoms (group, policy-attachment, membership) are
  # taggable, so there is nothing to thread tags into. We still compute the
  # merged tag set for uniformity / future use and surface config.tags via the
  # variable. Group resources are not tagged by AWS.
  tags = merge(local.module_tags, var.config.tags)

  # Manage membership only when at least one user is supplied. Avoids creating an
  # empty membership resource (which would still take exclusive ownership).
  manage_membership = length(var.config.users) > 0
}

# --- The IAM group ------------------------------------------------------------
module "group" {
  source = "../../atoms/iam/iam-group"

  config = {
    name = var.config.name
    path = var.config.path
  }
}

# --- Managed-policy attachments (one atom per ARN) ----------------------------
# Permissions are granted to the group, not to individual users (PCI DSS Req 7).
module "policy_attachment" {
  source   = "../../atoms/iam/iam-group-policy-attachment"
  for_each = toset(var.config.managed_policy_arns)

  config = {
    group      = module.group.manifest.name
    policy_arn = each.value
  }
}

# --- Group membership (created only when users are supplied) ------------------
# Manages the group's FULL membership exclusively.
module "membership" {
  source = "../../atoms/iam/iam-group-membership"
  count  = local.manage_membership ? 1 : 0

  config = {
    name  = "${var.config.name}-membership"
    group = module.group.manifest.name
    users = var.config.users
  }
}
