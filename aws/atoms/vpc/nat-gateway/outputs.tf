output "manifest" {
  description = "All outputs of the nat-gateway atom, collected on a single object."
  value = {
    id         = aws_nat_gateway.this.id
    public_ip  = aws_nat_gateway.this.public_ip
    private_ip = aws_nat_gateway.this.private_ip
  }
}
