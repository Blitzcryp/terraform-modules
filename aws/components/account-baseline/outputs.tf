output "manifest" {
  description = "All outputs of the account-baseline component, collected on a single object."
  value = {
    password_policy_min_length = module.password_policy.manifest.minimum_password_length
    password_policy_max_age    = module.password_policy.manifest.max_password_age
    password_reuse_prevention  = module.password_policy.manifest.password_reuse_prevention
  }
}
