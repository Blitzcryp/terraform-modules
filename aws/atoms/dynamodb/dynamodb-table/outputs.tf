output "manifest" {
  description = "All outputs of the DynamoDB table atom, collected on a single object."
  value = {
    id         = aws_dynamodb_table.this.id
    arn        = aws_dynamodb_table.this.arn
    name       = aws_dynamodb_table.this.name
    stream_arn = aws_dynamodb_table.this.stream_arn
  }
}
