output "manifest" {
  description = "All outputs of the CloudTrail atom, collected on a single object."
  value = {
    arn         = aws_cloudtrail.this.arn
    id          = aws_cloudtrail.this.id
    home_region = aws_cloudtrail.this.home_region
  }
}
