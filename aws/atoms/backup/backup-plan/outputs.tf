output "manifest" {
  description = "All outputs of the AWS Backup plan atom, collected on a single object."
  value = {
    arn     = aws_backup_plan.this.arn
    id      = aws_backup_plan.this.id
    version = aws_backup_plan.this.version
  }
}
