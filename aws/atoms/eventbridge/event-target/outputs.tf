output "manifest" {
  description = "All outputs of the EventBridge target atom, collected on a single object."
  value = {
    target_id = aws_cloudwatch_event_target.this.target_id
    rule      = aws_cloudwatch_event_target.this.rule
  }
}
