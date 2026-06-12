output "manifest" {
  description = "All outputs of the VPC atom, collected on a single object."
  value = {
    id                        = aws_vpc.this.id
    arn                       = aws_vpc.this.arn
    cidr_block                = aws_vpc.this.cidr_block
    default_security_group_id = aws_default_security_group.this.id
    main_route_table_id       = aws_vpc.this.main_route_table_id
  }
}
