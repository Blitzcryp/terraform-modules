output "manifest" {
  description = "All outputs of the route-table atom, collected on a single object."
  value = {
    id             = aws_route_table.this.id
    arn            = aws_route_table.this.arn
    route_table_id = aws_route_table.this.id
  }
}
