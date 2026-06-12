output "manifest" {
  description = "All outputs of the EFS file system atom, collected on a single object."
  value = {
    id       = aws_efs_file_system.this.id
    arn      = aws_efs_file_system.this.arn
    dns_name = aws_efs_file_system.this.dns_name
  }
}
