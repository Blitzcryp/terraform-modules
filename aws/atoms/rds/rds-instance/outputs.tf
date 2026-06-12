output "manifest" {
  description = "All outputs of the RDS instance atom, collected on a single object."
  value = {
    id                     = aws_db_instance.this.id
    arn                    = aws_db_instance.this.arn
    endpoint               = aws_db_instance.this.endpoint
    address                = aws_db_instance.this.address
    port                   = aws_db_instance.this.port
    master_user_secret_arn = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
    resource_id            = aws_db_instance.this.resource_id
  }
}
