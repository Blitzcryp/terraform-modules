<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the CloudFront distribution. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so a<br/>caller supplying only the required origins + default\_cache\_behavior gets a<br/>distribution that:<br/>  - serves viewers over TLS 1.2+ (minimum\_protocol\_version = TLSv1.2\_2021, PCI Req 4),<br/>  - redirects all viewer requests to HTTPS (viewer\_protocol\_policy = redirect-to-https),<br/>  - ships access logs to S3 when log\_bucket is set (PCI Req 10).<br/>Insecure choices (weak TLS, allow-all viewer protocol) require flipping an<br/>explicit `allow_*` escape hatch.<br/><br/>APPLY-TIME NOTES:<br/>  - acm\_certificate\_arn MUST be an ACM cert in us-east-1 (CloudFront requires<br/>    certs in us-east-1 regardless of distribution region). When null, the<br/>    distribution uses the default *.cloudfront.net certificate and aliases<br/>    must be empty.<br/>  - web\_acl\_id MUST reference a WAFv2 web ACL ARN created with CLOUDFRONT<br/>    scope in us-east-1 (or a WAF Classic web ACL id). | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    comment             = optional(string)<br/>    aliases             = optional(list(string), [])<br/>    default_root_object = optional(string, "index.html")<br/>    price_class         = optional(string, "PriceClass_100")<br/>    web_acl_id          = optional(string) # WAFv2 ARN (CLOUDFRONT scope, us-east-1) or WAF Classic id<br/><br/>    # --- TLS / viewer certificate (PCI DSS Req 4) ---<br/>    # When acm_certificate_arn is null the default CloudFront cert is used.<br/>    acm_certificate_arn      = optional(string)<br/>    minimum_protocol_version = optional(string, "TLSv1.2_2021")<br/>    ssl_support_method       = optional(string, "sni-only")<br/><br/>    # --- Origins (required) ---<br/>    origins = list(object({<br/>      domain_name              = string<br/>      origin_id                = string<br/>      origin_access_control_id = optional(string) # set for private S3 origins (OAC)<br/>      origin_path              = optional(string)<br/>      s3_origin_config = optional(object({<br/>        origin_access_identity = optional(string, "")<br/>      }))<br/>      custom_origin_config = optional(object({<br/>        http_port                = optional(number, 80)<br/>        https_port               = optional(number, 443)<br/>        origin_protocol_policy   = optional(string, "https-only")<br/>        origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])<br/>        origin_read_timeout      = optional(number)<br/>        origin_keepalive_timeout = optional(number)<br/>      }))<br/>    }))<br/><br/>    # --- Default cache behavior (required) ---<br/>    default_cache_behavior = object({<br/>      target_origin_id       = string<br/>      allowed_methods        = optional(list(string), ["GET", "HEAD"])<br/>      cached_methods         = optional(list(string), ["GET", "HEAD"])<br/>      viewer_protocol_policy = optional(string, "redirect-to-https")<br/>      compress               = optional(bool, true)<br/>      cache_policy_id        = optional(string) # use this OR forwarded_values<br/>      forwarded_values = optional(object({<br/>        query_string = optional(bool, false)<br/>        headers      = optional(list(string), [])<br/>        cookies = optional(object({<br/>          forward = optional(string, "none")<br/>        }), {})<br/>      }))<br/>    })<br/><br/>    # --- Ordered cache behaviors (optional) ---<br/>    ordered_cache_behaviors = optional(list(object({<br/>      path_pattern           = string<br/>      target_origin_id       = string<br/>      allowed_methods        = optional(list(string), ["GET", "HEAD"])<br/>      cached_methods         = optional(list(string), ["GET", "HEAD"])<br/>      viewer_protocol_policy = optional(string, "redirect-to-https")<br/>      compress               = optional(bool, true)<br/>      cache_policy_id        = optional(string)<br/>      forwarded_values = optional(object({<br/>        query_string = optional(bool, false)<br/>        headers      = optional(list(string), [])<br/>        cookies = optional(object({<br/>          forward = optional(string, "none")<br/>        }), {})<br/>      }))<br/>    })), [])<br/><br/>    # --- Access logging (PCI DSS Req 10) ---<br/>    # When log_bucket is set, a logging_config is emitted. The bucket must be the<br/>    # S3 bucket *domain name* (e.g. my-logs.s3.amazonaws.com) and must have ACLs<br/>    # enabled / log-delivery permission (see component for the caveat).<br/>    log_bucket          = optional(string)<br/>    log_prefix          = optional(string)<br/>    log_include_cookies = optional(bool, false)<br/><br/>    # --- Geo restriction ---<br/>    geo_restriction = optional(object({<br/>      restriction_type = optional(string, "none")<br/>      locations        = optional(list(string), [])<br/>    }), { restriction_type = "none" })<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Permit a minimum_protocol_version weaker than TLSv1.2_2021.<br/>    allow_weak_tls = optional(bool, false)<br/>    # Permit viewer_protocol_policy = "allow-all" (serves plain HTTP).<br/>    allow_insecure_viewer = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CloudFront distribution atom, collected on a single object. |
<!-- END_TF_DOCS -->