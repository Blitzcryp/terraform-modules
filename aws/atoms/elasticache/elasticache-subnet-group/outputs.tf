output "manifest" {
  description = "All outputs of the ElastiCache subnet group atom, collected on a single object."
  value = {
    name = aws_elasticache_subnet_group.this.name
    arn  = aws_elasticache_subnet_group.this.arn
  }
}
