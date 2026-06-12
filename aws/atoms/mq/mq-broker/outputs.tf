output "manifest" {
  description = "All outputs of the MQ broker atom, collected on a single object."
  value = {
    id        = aws_mq_broker.this.id
    arn       = aws_mq_broker.this.arn
    endpoints = try(flatten(aws_mq_broker.this.instances[*].endpoints), null)
  }
}
