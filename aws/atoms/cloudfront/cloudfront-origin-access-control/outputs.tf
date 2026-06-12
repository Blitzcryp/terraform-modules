output "manifest" {
  description = "All outputs of the CloudFront origin access control atom, collected on a single object."
  value = {
    id   = aws_cloudfront_origin_access_control.this.id
    etag = aws_cloudfront_origin_access_control.this.etag
  }
}
