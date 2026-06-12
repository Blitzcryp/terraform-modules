output "manifest" {
  description = "All outputs of the CloudFront distribution atom, collected on a single object."
  value = {
    id             = aws_cloudfront_distribution.this.id
    arn            = aws_cloudfront_distribution.this.arn
    domain_name    = aws_cloudfront_distribution.this.domain_name
    hosted_zone_id = aws_cloudfront_distribution.this.hosted_zone_id
    status         = aws_cloudfront_distribution.this.status
  }
}
