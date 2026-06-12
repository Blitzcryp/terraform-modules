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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_associations"></a> [associations](#module\_associations) | ../../atoms/waf/wafv2-web-acl-association | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_web_acl"></a> [web\_acl](#module\_web\_acl) | ../../atoms/waf/wafv2-web-acl | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.retention_guard](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the waf component: a WAFv2 Web ACL with request logging to a<br/>dedicated, KMS-encrypted CloudWatch log group, and optional associations to<br/>regional resources (ALBs, API Gateway stages, ...). All inputs live on this<br/>single object.<br/><br/>PCI-DSS-compliant defaults are baked into the optional() fields, so supplying<br/>only the required `name` yields a compliant ACL that:<br/>  - enables the three AWS baseline managed rule groups (Common, KnownBadInputs,<br/>    SQLi) via the wafv2-web-acl atom default,<br/>  - ships request logs to a KMS-encrypted CloudWatch log group with >= 1 year<br/>    retention (PCI DSS Req 10),<br/>  - owns a CMK whose policy authorises the regional CloudWatch Logs service.<br/>Insecure choices require flipping escape hatches on the underlying atoms. | <pre>object({<br/>    name  = string                       # required — base name for the ACL, log group, and CMK alias<br/>    scope = optional(string, "REGIONAL") # REGIONAL (ALB/APIGW) | CLOUDFRONT<br/><br/>    # AWS-managed rule groups. null => the wafv2-web-acl atom's secure default<br/>    # (the three AWS baseline groups). Override to extend/replace.<br/>    managed_rule_groups = optional(list(object({<br/>      name              = string<br/>      vendor_name       = optional(string, "AWS")<br/>      priority          = number<br/>      override_to_count = optional(bool, false)<br/>    })))<br/><br/>    # Optional rate-based rule (requests per 5-min per IP). null = no rate limit.<br/>    rate_limit = optional(number)<br/><br/>    # Regional resource ARNs to protect. One association atom is created per ARN.<br/>    # Only valid when scope = REGIONAL (CLOUDFRONT ACLs attach via the CDN).<br/>    associate_resource_arns = optional(list(string), [])<br/><br/>    # --- Logging (PCI DSS Req 10) ----------------------------------------<br/>    # BYO CMK ARN for the log group. null => the component creates a CMK whose<br/>    # policy authorises the regional CloudWatch Logs service principal.<br/>    kms_key_arn        = optional(string)<br/>    log_retention_days = optional(number, 365) # >= 1 year of WAF request logs<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the waf component, collected on a single object. |
<!-- END_TF_DOCS -->