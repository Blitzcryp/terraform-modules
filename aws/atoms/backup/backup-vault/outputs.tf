output "manifest" {
  description = "All outputs of the AWS Backup vault atom, collected on a single object."
  value = {
    arn  = aws_backup_vault.this.arn
    name = aws_backup_vault.this.name
    # Number of stored recovery points (exported by the vault resource).
    recovery_points = aws_backup_vault.this.recovery_points
  }
}
