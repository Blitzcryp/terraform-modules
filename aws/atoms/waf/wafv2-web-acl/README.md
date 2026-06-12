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
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_logging_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the WAFv2 Web ACL. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so passing<br/>only the required fields yields a compliant ACL: managed rule groups for the<br/>OWASP-style common set, known-bad inputs and SQLi are enabled, request<br/>metrics/sampling are on, and logging is required. Insecure choices require<br/>flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name        = string                                                         # required<br/>    description = optional(string, "Managed by terraform (atoms/wafv2-web-acl)") # secure default<br/><br/>    # --- Core controls (PCI DSS Req 6.4.x: protect public-facing web apps) ---<br/>    scope          = optional(string, "REGIONAL") # REGIONAL | CLOUDFRONT<br/>    default_action = optional(string, "allow")    # allow | block<br/><br/>    # AWS-managed rule groups, ON by default. Override the list to extend/replace.<br/>    managed_rule_groups = optional(list(object({<br/>      name              = string<br/>      vendor_name       = optional(string, "AWS")<br/>      priority          = number<br/>      override_to_count = optional(bool, false) # count-only (test) instead of enforcing<br/>      })), [<br/>      { name = "AWSManagedRulesCommonRuleSet", priority = 0 },<br/>      { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 1 },<br/>      { name = "AWSManagedRulesSQLiRuleSet", priority = 2 },<br/>    ])<br/><br/>    # Optional rate-based rule. null = no rate limit. When set, must be 100..2e9.<br/>    rate_limit = optional(number)<br/><br/>    # --- Logging (PCI DSS Req 10: log all access to the in-scope web tier) ---<br/>    # ARN of a CloudWatch Logs log group (name must start with aws-waf-logs-),<br/>    # Kinesis Firehose, or S3 bucket. Required unless allow_logging_disabled=true.<br/>    log_destination_arn = optional(string)<br/><br/>    # Passthrough for caller-authored custom rules (already-formed rule objects).<br/>    custom_rules = optional(list(any), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_logging_disabled = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the WAFv2 Web ACL atom, collected on a single object. |
<!-- END_TF_DOCS -->