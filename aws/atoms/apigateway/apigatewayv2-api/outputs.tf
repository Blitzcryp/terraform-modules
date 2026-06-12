output "manifest" {
  description = "All outputs of the API Gateway v2 API atom, collected on a single object."
  value = {
    id            = aws_apigatewayv2_api.this.id
    arn           = aws_apigatewayv2_api.this.arn
    api_endpoint  = aws_apigatewayv2_api.this.api_endpoint
    execution_arn = aws_apigatewayv2_api.this.execution_arn
  }
}
