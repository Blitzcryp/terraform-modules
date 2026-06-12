# <ATOM NAME> atom — wraps exactly one logical AWS resource.
# Rules (see /CONVENTIONS.md):
#   - Do NOT instantiate other modules. Call aws_* resources directly.
#   - Take all dependencies (vpc_id, subnet_id, kms_key_arn, ...) as fields on config.
#   - One `config` input object; one `manifest` output object.
#   - Secure defaults; every control overridable; insecure overrides gated by an escape hatch.

locals {
  # Only hardcoded tag is this module's path. Global tags (Environment, Owner,
  # Compliance, ManagedBy, ...) come from the AWS provider's default_tags, set
  # ONCE at the root (see aws/examples/global-config). Don't re-declare them here.
  module_tags = { Module = "atoms/<FAMILY>/<ATOM_NAME>" }
  tags        = merge(local.module_tags, var.config.tags)
}

# resource "aws_<resource>" "this" {
#   ...
#   tags = local.tags
#
#   lifecycle {
#     precondition {
#       condition     = var.config.<secure_control> || var.config.allow_<insecure>
#       error_message = "<control> relaxed without config.allow_<insecure>=true. File a PCI exception (security@emag.ro)."
#     }
#   }
# }
