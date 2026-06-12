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
| <a name="module_flow_log_role"></a> [flow\_log\_role](#module\_flow\_log\_role) | ../../atoms/iam-role | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch-log-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the audit-logging component (PCI DSS Req 10 logging<br/>backbone). All inputs live on this single object. PCI-compliant defaults are<br/>baked into the optional() fields, so the caller only has to supply the<br/>required `name_prefix`. Insecure choices require flipping an explicit<br/>`allow_*` escape hatch that is passed down to the underlying atoms. | <pre>object({<br/>    # name_prefix is REQUIRED: the base name for the log group, KMS alias and<br/>    # flow-log role. The caller must decide it. No default.<br/>    name_prefix = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---<br/>    retention_in_days = optional(number, 365) # >= 1 year of audit logs<br/>    kms_key_arn       = optional(string)      # BYOK: if set, no kms-key atom is created<br/>    log_group_class   = optional(string, "STANDARD")<br/><br/>    create_flow_log_role        = optional(bool, true)<br/>    flow_log_role_trust_service = optional(string, "vpc-flow-logs.amazonaws.com")<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_no_retention = optional(bool, false) # passed to the log-group atom<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the audit-logging component, collected on a single object. |
<!-- END_TF_DOCS -->