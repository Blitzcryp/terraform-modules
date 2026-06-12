# CloudFront Origin Access Control (OAC). One logical resource. No module calls.
# An OAC has no tags (the AWS API does not support tagging this resource), so the
# repo-wide tag locals are intentionally omitted here; identity/global tags are
# carried on the distribution that references this OAC.

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.config.name
  description                       = var.config.description
  origin_access_control_origin_type = var.config.origin_access_control_origin_type
  signing_behavior                  = var.config.signing_behavior
  signing_protocol                  = var.config.signing_protocol
}
