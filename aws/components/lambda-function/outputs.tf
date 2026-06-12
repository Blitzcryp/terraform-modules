output "manifest" {
  description = "All outputs of the lambda-function component, collected on a single object."
  value = {
    function_arn   = module.lambda_function.manifest.arn
    function_name  = module.lambda_function.manifest.function_name
    invoke_arn     = module.lambda_function.manifest.invoke_arn
    role_arn       = module.exec_role.manifest.arn
    log_group_name = module.log_group.manifest.name
    kms_key_arn    = local.effective_kms_arn

    # null when the function is not attached to a VPC.
    security_group_id = local.has_vpc ? module.security_group[0].manifest.id : null
  }
}
