output "manifest" {
  description = "All outputs of the Lambda function atom, collected on a single object."
  value = {
    arn           = aws_lambda_function.this.arn
    function_name = aws_lambda_function.this.function_name
    invoke_arn    = aws_lambda_function.this.invoke_arn
    qualified_arn = aws_lambda_function.this.qualified_arn
    version       = aws_lambda_function.this.version
    last_modified = aws_lambda_function.this.last_modified
  }
}
