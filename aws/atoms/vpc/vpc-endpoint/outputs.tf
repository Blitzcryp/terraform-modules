output "manifest" {
  description = "All outputs of the VPC endpoint atom, collected on a single object."
  value = {
    id                    = aws_vpc_endpoint.this.id
    arn                   = aws_vpc_endpoint.this.arn
    dns_entry             = aws_vpc_endpoint.this.dns_entry
    network_interface_ids = aws_vpc_endpoint.this.network_interface_ids
    state                 = aws_vpc_endpoint.this.state
  }
}
