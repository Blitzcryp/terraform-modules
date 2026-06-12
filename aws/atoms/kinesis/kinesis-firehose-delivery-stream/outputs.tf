output "manifest" {
  description = "All outputs of the Kinesis Firehose delivery stream atom, collected on a single object."
  value = {
    arn  = aws_kinesis_firehose_delivery_stream.this.arn
    name = aws_kinesis_firehose_delivery_stream.this.name
  }
}
