output "manifest" {
  description = "All outputs of the MSK cluster atom, collected on a single object."
  value = {
    arn                      = aws_msk_cluster.this.arn
    cluster_name             = aws_msk_cluster.this.cluster_name
    bootstrap_brokers_tls    = try(aws_msk_cluster.this.bootstrap_brokers_tls, null)
    zookeeper_connect_string = try(aws_msk_cluster.this.zookeeper_connect_string, null)
    current_version          = aws_msk_cluster.this.current_version
  }
}
