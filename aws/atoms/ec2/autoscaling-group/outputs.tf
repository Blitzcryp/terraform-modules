output "manifest" {
  description = "All outputs of the Auto Scaling group atom, collected on a single object."
  value = {
    id   = aws_autoscaling_group.this.id
    arn  = aws_autoscaling_group.this.arn
    name = aws_autoscaling_group.this.name
  }
}
