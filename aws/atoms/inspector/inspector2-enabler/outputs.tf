output "manifest" {
  description = "All outputs of the Inspector v2 enabler atom, collected on a single object."
  value = {
    id             = aws_inspector2_enabler.this.id
    resource_types = aws_inspector2_enabler.this.resource_types
    account_ids    = aws_inspector2_enabler.this.account_ids
  }
}
