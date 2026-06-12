output "manifest" {
  description = "All outputs of the SQS queue atom, collected on a single object."
  value = {
    id      = aws_sqs_queue.this.id
    arn     = aws_sqs_queue.this.arn
    name    = aws_sqs_queue.this.name
    url     = aws_sqs_queue.this.url
    dlq_arn = try(aws_sqs_queue.dlq[0].arn, null)
    dlq_url = try(aws_sqs_queue.dlq[0].url, null)
  }
}
