output "manifest" {
  description = "All outputs of the elasticache component, collected on a single object."
  # These are identifiers/endpoints/ARNs, not secrets. They are tainted sensitive
  # only because var.config (which carries the AUTH token) is sensitive;
  # nonsensitive() unwraps the non-secret values. The AUTH token is never exposed.
  value = {
    replication_group_id = module.replication_group.manifest.id
    primary_endpoint     = module.replication_group.manifest.primary_endpoint_address
    reader_endpoint      = module.replication_group.manifest.reader_endpoint_address
    port                 = module.replication_group.manifest.port
    security_group_id    = nonsensitive(module.security_group.manifest.id)
    kms_key_arn          = nonsensitive(local.kms_key_arn)
  }
}
