output "manifest" {
  description = "All outputs of the secure-network component, collected on a single object."
  value = {
    vpc_id                    = module.vpc.manifest.id
    vpc_arn                   = module.vpc.manifest.arn
    vpc_cidr                  = module.vpc.manifest.cidr_block
    default_security_group_id = module.vpc.manifest.default_security_group_id

    subnet_ids         = [for k, m in module.subnet : m.manifest.id]
    subnet_ids_by_name = { for k, m in module.subnet : k => m.manifest.id }

    # Created sink ARN, BYO ARN, or null when flow logs are disabled.
    flow_log_destination_arn = local.flow_log_destination_arn
    flow_log_role_arn        = local.flow_log_role_arn

    # --- Routing (additive) ---
    internet_gateway_id     = local.create_igw ? module.internet_gateway[0].manifest.id : null
    nat_gateway_ids         = [for k, m in module.nat_gateway : m.manifest.id]
    public_route_table_id   = length(module.public_route_table) > 0 ? module.public_route_table[0].manifest.id : null
    private_route_table_ids = [for k, m in module.private_route_table : m.manifest.id]
  }
}
