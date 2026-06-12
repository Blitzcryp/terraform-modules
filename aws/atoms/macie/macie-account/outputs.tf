output "manifest" {
  description = "All outputs of the Amazon Macie account atom, collected on a single object."
  value = {
    id           = aws_macie2_account.this.id
    account_id   = aws_macie2_account.this.id
    service_role = aws_macie2_account.this.service_role
  }
}
