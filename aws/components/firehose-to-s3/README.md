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
| <a name="module_delivery_bucket"></a> [delivery\_bucket](#module\_delivery\_bucket) | ../../atoms/s3/s3-bucket | n/a |
| <a name="module_firehose"></a> [firehose](#module\_firehose) | ../../atoms/kinesis/kinesis-firehose-delivery-stream | n/a |
| <a name="module_firehose_role"></a> [firehose\_role](#module\_firehose\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the firehose-to-s3 component: an encrypted Kinesis Data<br/>Firehose delivery stream that lands records in a private, KMS-encrypted S3<br/>bucket, with delivery errors captured in a KMS-encrypted CloudWatch log<br/>group. The component owns and wires together the delivery bucket, the CMK<br/>(unless a BYO key is supplied), the error log group, the firehose delivery<br/>IAM role and the firehose stream itself. PCI DSS Req 3 (encryption) and Req<br/>10 (logging) backbone. PCI-compliant defaults are baked into the optional()<br/>fields, so the caller only has to supply the required `name`. | <pre>object({<br/>    # name is REQUIRED: base name for the stream, delivery bucket, KMS alias,<br/>    # error log group and delivery role. The caller must decide it. No default.<br/>    name = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) -<br/>    kms_key_arn        = optional(string)      # BYOK: if set, no kms-key atom is created<br/>    buffering_size     = optional(number, 5)   # MB, 1-128<br/>    buffering_interval = optional(number, 300) # seconds, 0-900<br/>    prefix             = optional(string, "data/")<br/>    log_retention_days = optional(number, 365) # >= 1 year of CloudWatch error logs<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the firehose-to-s3 component, collected on a single object. |
<!-- END_TF_DOCS -->