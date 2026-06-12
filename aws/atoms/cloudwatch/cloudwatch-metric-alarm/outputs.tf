output "manifest" {
  description = "All outputs of the CloudWatch metric alarm atom, collected on a single object."
  value = {
    arn        = aws_cloudwatch_metric_alarm.this.arn
    alarm_name = aws_cloudwatch_metric_alarm.this.alarm_name
    id         = aws_cloudwatch_metric_alarm.this.id
  }
}
