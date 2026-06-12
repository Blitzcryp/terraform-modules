# --- Account IAM password policy (PCI DSS Req 8: identify & authenticate) -----
# The account password policy is an account-level singleton. The component maps
# its high-level knobs onto the atom's config and inherits the atom's secure
# defaults for the character-complexity controls it does not surface. Additional
# account-level atoms (e.g. IAM access analyzer, account-wide EBS encryption)
# can be composed alongside this one as the baseline grows.
module "password_policy" {
  source = "../../atoms/iam/account-password-policy"

  config = {
    minimum_password_length   = var.config.password_minimum_length
    max_password_age          = var.config.password_max_age
    password_reuse_prevention = var.config.password_reuse_prevention
    require_symbols           = var.config.require_symbols
    tags                      = var.config.tags
  }
}
