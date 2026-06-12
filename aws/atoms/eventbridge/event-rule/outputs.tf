output "manifest" {
  description = "All outputs of the EventBridge rule atom, collected on a single object."
  value = {
    arn            = aws_cloudwatch_event_rule.this.arn
    name           = aws_cloudwatch_event_rule.this.name
    id             = aws_cloudwatch_event_rule.this.id
    event_bus_name = aws_cloudwatch_event_rule.this.event_bus_name
  }
}
