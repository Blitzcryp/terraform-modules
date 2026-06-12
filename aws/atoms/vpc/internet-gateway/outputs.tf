output "manifest" {
  description = "All outputs of the internet-gateway atom, collected on a single object."
  value = {
    id  = aws_internet_gateway.this.id
    arn = aws_internet_gateway.this.arn
  }
}
