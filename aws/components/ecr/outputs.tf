output "manifest" {
  description = "All outputs of the ecr component, collected on a single object."
  value = {
    repository_url  = module.repository.manifest.repository_url
    repository_arn  = module.repository.manifest.arn
    repository_name = module.repository.manifest.name

    # The effective CMK the repository is encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn

    # Whether account-level Inspector ECR scanning was enabled by this component.
    inspector_enabled = var.config.enable_inspector
  }
}
