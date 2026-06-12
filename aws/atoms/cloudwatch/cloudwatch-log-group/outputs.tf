output "manifest" {
  description = "All outputs of the CloudWatch log group atom, collected on a single object."
  value = {
    name = aws_cloudwatch_log_group.this.name
    arn  = aws_cloudwatch_log_group.this.arn
  }
}
