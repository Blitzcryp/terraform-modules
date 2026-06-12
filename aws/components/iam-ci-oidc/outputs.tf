output "manifest" {
  description = "All outputs of the iam-ci-oidc component, collected on a single object."
  value = {
    role_arn  = module.ci_role.manifest.arn
    role_name = module.ci_role.manifest.name

    # The OIDC provider the role federates to: created by this component or the
    # reused ARN the caller supplied.
    oidc_provider_arn = local.effective_provider_arn
  }
}
