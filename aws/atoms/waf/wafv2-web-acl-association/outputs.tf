output "manifest" {
  description = "All outputs of the WAFv2 Web ACL association atom, collected on a single object."
  value = {
    id = aws_wafv2_web_acl_association.this.id
  }
}
