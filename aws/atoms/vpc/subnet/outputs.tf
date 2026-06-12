output "manifest" {
  description = "All outputs of the subnet atom, collected on a single object."
  value = {
    id                = aws_subnet.this.id
    arn               = aws_subnet.this.arn
    cidr_block        = aws_subnet.this.cidr_block
    availability_zone = aws_subnet.this.availability_zone
  }
}
