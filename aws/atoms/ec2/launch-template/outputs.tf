output "manifest" {
  description = "All outputs of the launch template atom, collected on a single object."
  value = {
    id              = aws_launch_template.this.id
    arn             = aws_launch_template.this.arn
    latest_version  = aws_launch_template.this.latest_version
    default_version = aws_launch_template.this.default_version
  }
}
