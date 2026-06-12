output "manifest" {
  description = "All outputs of the EFS access point atom, collected on a single object."
  value = {
    id  = aws_efs_access_point.this.id
    arn = aws_efs_access_point.this.arn
  }
}
