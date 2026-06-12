output "manifest" {
  description = "All outputs of the Aurora cluster atom, collected on a single object."
  value = {
    cluster_id             = aws_rds_cluster.this.id
    cluster_arn            = aws_rds_cluster.this.arn
    endpoint               = aws_rds_cluster.this.endpoint
    reader_endpoint        = aws_rds_cluster.this.reader_endpoint
    port                   = aws_rds_cluster.this.port
    master_user_secret_arn = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
    instance_ids           = aws_rds_cluster_instance.this[*].id
  }
}
