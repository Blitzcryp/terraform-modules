output "manifest" {
  description = "All outputs of the elastic-ip atom, collected on a single object."
  value = {
    id            = aws_eip.this.id
    allocation_id = aws_eip.this.allocation_id
    public_ip     = aws_eip.this.public_ip
  }
}
