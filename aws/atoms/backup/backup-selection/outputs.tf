output "manifest" {
  description = "All outputs of the AWS Backup selection atom, collected on a single object."
  value = {
    id   = aws_backup_selection.this.id
    name = aws_backup_selection.this.name
  }
}
