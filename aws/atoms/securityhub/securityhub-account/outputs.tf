output "manifest" {
  description = "All outputs of the Security Hub account atom, collected on a single object."
  value = {
    account_id        = aws_securityhub_account.this.id
    arn               = aws_securityhub_account.this.arn
    enabled_standards = [for s in aws_securityhub_standards_subscription.this : s.standards_arn]
  }
}
