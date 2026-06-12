output "manifest" {
  description = "All outputs of the DB parameter group atom, collected on a single object."
  value = {
    id   = aws_db_parameter_group.this.id
    arn  = aws_db_parameter_group.this.arn
    name = aws_db_parameter_group.this.name
  }
}
