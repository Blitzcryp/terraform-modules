output "manifest" {
  description = "All outputs of the DB subnet group atom, collected on a single object."
  value = {
    id   = aws_db_subnet_group.this.id
    arn  = aws_db_subnet_group.this.arn
    name = aws_db_subnet_group.this.name
  }
}
