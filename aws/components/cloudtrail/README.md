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
| <a name="module_cloudwatch_role"></a> [cloudwatch\_role](#module\_cloudwatch\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | ../../atoms/s3/s3-bucket | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_trail"></a> [trail](#module\_trail) | ../../atoms/cloudtrail/cloudtrail | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the cloudtrail component: an encrypted, log-file-validated,<br/>multi-region CloudTrail trail together with the log store it needs (S3 bucket,<br/>KMS CMK, CloudWatch log group and the CloudTrail->CWL delivery role). PCI DSS<br/>Req 10 backbone. PCI-compliant defaults are baked into the optional() fields,<br/>so the caller only has to supply the required `name`. Insecure choices require<br/>flipping an explicit `allow_*` escape hatch passed down to the atoms. | <pre>object({<br/>    # name is REQUIRED: base name for the trail, log bucket, KMS alias, log group<br/>    # and delivery role. The caller must decide it. No default.<br/>    name = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---<br/>    kms_key_arn           = optional(string)      # BYOK: if set, no kms-key atom is created<br/>    log_retention_days    = optional(number, 365) # >= 1 year of CloudWatch audit logs<br/>    is_organization_trail = optional(bool, false)<br/>    s3_key_prefix         = optional(string) # null = logs at the bucket root prefix<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the cloudtrail component, collected on a single object. |
<!-- END_TF_DOCS -->