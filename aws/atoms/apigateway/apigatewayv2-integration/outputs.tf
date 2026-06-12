output "manifest" {
  description = "All outputs of the API Gateway v2 integration atom, collected on a single object."
  value = {
    id             = aws_apigatewayv2_integration.this.id
    integration_id = aws_apigatewayv2_integration.this.id
  }
}
