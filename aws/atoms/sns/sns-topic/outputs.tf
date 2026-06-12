output "manifest" {
  description = "All outputs of the SNS topic atom, collected on a single object."
  value = {
    id   = aws_sns_topic.this.id
    arn  = aws_sns_topic.this.arn
    name = aws_sns_topic.this.name
  }
}
