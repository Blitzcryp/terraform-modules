output "manifest" {
  description = "All outputs of the RDS cluster parameter group atom, collected on a single object."
  value = {
    id   = aws_rds_cluster_parameter_group.this.id
    arn  = aws_rds_cluster_parameter_group.this.arn
    name = aws_rds_cluster_parameter_group.this.name
  }
}
