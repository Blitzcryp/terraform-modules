output "manifest" {
  description = "All outputs of the API Gateway v2 route atom, collected on a single object."
  value = {
    id       = aws_apigatewayv2_route.this.id
    route_id = aws_apigatewayv2_route.this.id
  }
}
