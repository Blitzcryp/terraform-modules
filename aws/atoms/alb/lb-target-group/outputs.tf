output "manifest" {
  description = "All outputs of the LB target group atom, collected on a single object."
  value = {
    id         = aws_lb_target_group.this.id
    arn        = aws_lb_target_group.this.arn
    arn_suffix = aws_lb_target_group.this.arn_suffix
    name       = aws_lb_target_group.this.name
  }
}
