output "manifest" {
  description = "All outputs of the Kinesis data stream atom, collected on a single object."
  value = {
    id   = aws_kinesis_stream.this.id
    arn  = aws_kinesis_stream.this.arn
    name = aws_kinesis_stream.this.name
  }
}
