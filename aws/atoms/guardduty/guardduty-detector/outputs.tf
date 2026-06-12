output "manifest" {
  description = "All outputs of the GuardDuty detector atom, collected on a single object."
  value = {
    detector_id = aws_guardduty_detector.this.id
    arn         = aws_guardduty_detector.this.arn
    account_id  = aws_guardduty_detector.this.account_id
    features    = { for k, f in aws_guardduty_detector_feature.this : k => f.status }
  }
}
