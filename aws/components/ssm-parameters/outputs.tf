output "manifest" {
  description = "All outputs of the ssm-parameters component, collected on a single object."
  sensitive   = true # parameter atom manifests are value-tainted; this collection inherits it
  value = {
    # created-or-BYO ARN that encrypts every parameter.
    kms_key_arn = local.kms_key_arn

    # Maps keyed by the logical parameter name (the map key, not the full name).
    parameter_arns  = { for k, m in module.parameter : k => m.manifest.arn }
    parameter_names = { for k, m in module.parameter : k => m.manifest.name }
  }
}
