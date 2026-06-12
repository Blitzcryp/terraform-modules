output "manifest" {
  description = "All outputs of the http-api component, collected on a single object."
  value = {
    api_id        = module.api.manifest.id
    api_endpoint  = module.api.manifest.api_endpoint
    invoke_url    = module.stage.manifest.invoke_url
    execution_arn = module.api.manifest.execution_arn

    log_group_name = module.access_log_group.manifest.name

    # Effective CMK the access-log group is encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn
  }
}
