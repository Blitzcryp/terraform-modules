variable "config" {
  description = <<-EOT
    Configuration for the WAFv2 Web ACL association (aws_wafv2_web_acl_association).
    All inputs live on this single object. This atom binds an existing REGIONAL
    Web ACL to a regional resource (an Application Load Balancer, API Gateway
    stage, AppSync GraphQL API, Cognito user pool, etc.). Both ARNs are required;
    the caller decides them. `tags` is accepted for interface uniformity across
    atoms but the underlying resource is not taggable.
  EOT

  type = object({
    web_acl_arn  = string # required — ARN of the WAFv2 Web ACL (REGIONAL scope)
    resource_arn = string # required — ARN of the resource to protect (ALB / APIGW / ...)

    # Accepted for interface uniformity; aws_wafv2_web_acl_association is not taggable.
    tags = optional(map(string), {})
  })

  # no `default` here because both ARNs are required

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:wafv2:", var.config.web_acl_arn))
    error_message = "config.web_acl_arn must be a valid WAFv2 Web ACL ARN (arn:aws:wafv2:...)."
  }

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:", var.config.resource_arn))
    error_message = "config.resource_arn must be a valid AWS resource ARN (arn:aws:...)."
  }
}
