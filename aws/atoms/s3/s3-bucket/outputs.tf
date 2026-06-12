output "manifest" {
  description = "All outputs of the S3 bucket atom, collected on a single object."
  value = {
    id                          = aws_s3_bucket.this.id
    arn                         = aws_s3_bucket.this.arn
    bucket                      = aws_s3_bucket.this.bucket
    bucket_domain_name          = aws_s3_bucket.this.bucket_domain_name
    bucket_regional_domain_name = aws_s3_bucket.this.bucket_regional_domain_name
  }
}
