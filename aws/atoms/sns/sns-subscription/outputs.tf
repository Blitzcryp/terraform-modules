output "manifest" {
  description = "All outputs of the SNS subscription atom, collected on a single object."
  value = {
    id                   = aws_sns_topic_subscription.this.id
    arn                  = aws_sns_topic_subscription.this.arn
    owner_id             = aws_sns_topic_subscription.this.owner_id
    protocol             = aws_sns_topic_subscription.this.protocol
    endpoint             = aws_sns_topic_subscription.this.endpoint
    pending_confirmation = aws_sns_topic_subscription.this.pending_confirmation
  }
}
