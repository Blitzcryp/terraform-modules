output "manifest" {
  description = "All outputs of the CloudWatch log metric filter atom, collected on a single object."
  value = {
    id   = aws_cloudwatch_log_metric_filter.this.id
    name = aws_cloudwatch_log_metric_filter.this.name
  }
}
