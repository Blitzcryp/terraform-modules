<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_distribution"></a> [distribution](#module\_distribution) | ../../atoms/cloudfront/cloudfront-distribution | n/a |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | ../../atoms/s3/s3-bucket | n/a |
| <a name="module_oac"></a> [oac](#module\_oac) | ../../atoms/cloudfront/cloudfront-origin-access-control | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the cloudfront component: a secure CloudFront distribution<br/>fronting EITHER a private S3 origin (locked down via an Origin Access Control)<br/>OR a custom origin (e.g. an ALB / public hostname). When logging is enabled and<br/>no BYO log bucket is supplied, the component also owns a dedicated S3 access-log<br/>bucket. All inputs live on this single object.<br/><br/>PCI-DSS-compliant defaults are baked into the optional() fields, so supplying<br/>only `name` + exactly one origin yields a distribution that:<br/>  - serves viewers over TLS 1.2+ (minimum\_protocol\_version = TLSv1.2\_2021, PCI Req 4),<br/>  - redirects all viewer requests to HTTPS,<br/>  - fronts S3 origins via an OAC so the bucket needs no public access (PCI Req 1/7),<br/>  - ships access logs to S3 (PCI Req 10).<br/><br/>APPLY-TIME NOTES (read before apply):<br/>  - acm\_certificate\_arn MUST be an ACM certificate in us-east-1 (CloudFront<br/>    requires viewer certs in us-east-1 regardless of where anything else lives).<br/>    It is REQUIRED whenever `aliases` is non-empty; without it the distribution<br/>    serves only on its *.cloudfront.net domain using the default certificate.<br/>  - web\_acl\_arn MUST reference a WAFv2 web ACL created with CLOUDFRONT scope in<br/>    us-east-1 (or a WAF Classic web ACL id).<br/>  - LOGGING CAVEAT: CloudFront standard (legacy) access logging delivers logs<br/>    via the awslogsdelivery account and REQUIRES the target bucket to have ACLs<br/>    enabled (Object Ownership = BucketOwnerPreferred) and the log-delivery<br/>    grant. The s3-bucket atom defaults to BucketOwnerEnforced (ACLs disabled),<br/>    which CloudFront standard logging does NOT support. The owned log bucket is<br/>    therefore created with object\_ownership = "BucketOwnerPreferred"; you must<br/>    still grant the log-delivery ACL out of band, OR migrate to CloudFront v2<br/>    (CloudWatch Logs / Firehose) logging. For a fully managed flow, supply your<br/>    own ACL-enabled bucket domain via `log_bucket`. | <pre>object({<br/>    name = string # required — base name for the distribution and its child resources<br/><br/>    # --- Origin (exactly one of the two must be set) ---<br/>    # The S3 bucket REGIONAL domain name (e.g. my-bucket.s3.eu-central-1.amazonaws.com).<br/>    s3_origin_domain_name = optional(string)<br/>    # A custom origin hostname (e.g. an ALB DNS name or public API host).<br/>    custom_origin_domain_name = optional(string)<br/><br/>    # --- DNS / TLS (PCI DSS Req 4) ---<br/>    aliases = optional(list(string), [])<br/>    # ACM cert ARN in us-east-1 — REQUIRED if aliases is non-empty.<br/>    acm_certificate_arn = optional(string)<br/><br/>    # --- WAF (us-east-1, CLOUDFRONT scope) ---<br/>    web_acl_arn = optional(string)<br/><br/>    # --- Behavior / distribution knobs ---<br/>    default_root_object = optional(string, "index.html")<br/>    price_class         = optional(string, "PriceClass_100")<br/><br/>    # --- Access logging (PCI DSS Req 10) ---<br/>    enable_logging = optional(bool, true)<br/>    # BYO log bucket DOMAIN NAME (e.g. my-logs.s3.amazonaws.com). When set, the<br/>    # component does not create a bucket and assumes it is ACL-enabled with the<br/>    # CloudFront log-delivery grant attached.<br/>    log_bucket = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the cloudfront component, collected on a single object. |
<!-- END_TF_DOCS -->