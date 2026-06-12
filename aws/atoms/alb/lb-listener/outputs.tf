output "manifest" {
  description = "All outputs of the LB listener atom, collected on a single object."
  value = {
    id  = aws_lb_listener.this.id
    arn = aws_lb_listener.this.arn
  }
}
