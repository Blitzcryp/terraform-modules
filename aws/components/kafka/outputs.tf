output "manifest" {
  description = "All outputs of the kafka (Amazon MSK) component, collected on a single object."
  value = {
    cluster_arn           = module.msk_cluster.manifest.arn
    cluster_name          = module.msk_cluster.manifest.cluster_name
    bootstrap_brokers_tls = module.msk_cluster.manifest.bootstrap_brokers_tls

    security_group_id = module.security_group.manifest.id

    # The effective key the cluster + log group are encrypted with (created or BYO).
    kms_key_arn = local.effective_kms_arn

    log_group_name = module.log_group.manifest.name
  }
}
