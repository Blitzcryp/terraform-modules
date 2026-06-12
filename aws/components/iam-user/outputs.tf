output "manifest" {
  description = "All outputs of the iam-user component, collected on a single object."
  value = {
    user_arn  = module.user.manifest.arn
    user_name = module.user.manifest.name
    unique_id = module.user.manifest.unique_id
  }
}
