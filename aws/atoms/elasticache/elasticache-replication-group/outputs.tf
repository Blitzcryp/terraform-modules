output "manifest" {
  description = "All outputs of the ElastiCache replication group atom, collected on a single object."
  # These are AWS-computed identifiers/endpoints, not secrets. They are tainted
  # sensitive only because var.config (which carries the AUTH token) is sensitive;
  # nonsensitive() unwraps the non-secret attributes so callers can consume them.
  # The AUTH token itself is never exposed on the manifest.
  value = {
    id                       = nonsensitive(aws_elasticache_replication_group.this.id)
    arn                      = nonsensitive(aws_elasticache_replication_group.this.arn)
    primary_endpoint_address = nonsensitive(aws_elasticache_replication_group.this.primary_endpoint_address)
    reader_endpoint_address  = nonsensitive(aws_elasticache_replication_group.this.reader_endpoint_address)
    port                     = nonsensitive(aws_elasticache_replication_group.this.port)
    member_clusters          = nonsensitive(aws_elasticache_replication_group.this.member_clusters)
  }
}
