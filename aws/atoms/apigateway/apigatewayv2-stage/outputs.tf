output "manifest" {
  description = "All outputs of the API Gateway v2 stage atom, collected on a single object."
  value = {
    id         = aws_apigatewayv2_stage.this.id
    arn        = aws_apigatewayv2_stage.this.arn
    invoke_url = aws_apigatewayv2_stage.this.invoke_url
    name       = aws_apigatewayv2_stage.this.name
  }
}
