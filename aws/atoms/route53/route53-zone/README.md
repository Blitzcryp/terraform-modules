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
| [aws_route53_query_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Route53 hosted zone. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>passing only the required `name` yields a compliant zone (DNS query logging<br/>enabled for public zones — PCI DSS Req 10). Insecure choices require flipping<br/>an explicit `allow_*` escape hatch. | <pre>object({<br/>    name          = string # required — the DNS zone name<br/>    comment       = optional(string, "Managed by terraform (atoms/route53-zone)")<br/>    private_zone  = optional(bool, false)      # private zones cannot query-log<br/>    vpc_ids       = optional(list(string), []) # VPC associations (private zones)<br/>    force_destroy = optional(bool, false)      # delete even with records present<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 10: log all access) ---<br/>    # CloudWatch Logs group ARN for DNS query logging. For PUBLIC zones this<br/>    # group MUST live in us-east-1. null = no destination configured.<br/>    query_log_destination_arn = optional(string)<br/>    tags                      = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Permit a public zone with no query logging configured.<br/>    allow_query_logging_disabled = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Route53 zone atom, collected on a single object. |
<!-- END_TF_DOCS -->