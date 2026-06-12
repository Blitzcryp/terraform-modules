output "manifest" {
  description = "All outputs of the WAFv2 Web ACL atom, collected on a single object."
  value = {
    id              = aws_wafv2_web_acl.this.id
    arn             = aws_wafv2_web_acl.this.arn
    name            = aws_wafv2_web_acl.this.name
    capacity        = aws_wafv2_web_acl.this.capacity
    logging_enabled = local.logging_enabled
  }
}
