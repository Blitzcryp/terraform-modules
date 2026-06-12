output "manifest" {
  description = "All outputs of the network ACL atom, collected on a single object."
  value = {
    id  = aws_network_acl.this.id
    arn = aws_network_acl.this.arn
  }
}
