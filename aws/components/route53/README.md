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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_query_log_group"></a> [query\_log\_group](#module\_query\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_zone"></a> [zone](#module\_zone) | ../../atoms/route53/route53-zone | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the route53 component (a hosted zone with DNS query<br/>logging — PCI DSS Req 10). All inputs live on this single object. PCI<br/>compliant defaults are baked into the optional() fields, so the caller only<br/>has to supply the required `name`: a public zone gets a CloudWatch-Logs<br/>query-log destination encrypted with a CMK this component creates.<br/><br/>For PUBLIC zones the query-log group MUST live in us-east-1 (an AWS<br/>requirement for Route53 query logging). For PRIVATE zones query logging is<br/>not supported by Route53, so it is skipped entirely. Insecure choices flow<br/>down to the underlying atoms via their `allow_*` escape hatches. | <pre>object({<br/>    name         = string                     # required — the DNS zone name<br/>    private_zone = optional(bool, false)      # private zones cannot query-log<br/>    vpc_ids      = optional(list(string), []) # VPC associations (private zones)<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---<br/>    # BYO CMK for query-log encryption. null = this component creates one.<br/>    kms_key_arn        = optional(string)<br/>    log_retention_days = optional(number, 365) # >= 1 year of DNS query logs<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the route53 component, collected on a single object. |
<!-- END_TF_DOCS -->