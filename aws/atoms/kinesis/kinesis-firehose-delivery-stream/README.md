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
| [aws_kinesis_firehose_delivery_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Kinesis Data Firehose delivery stream (extended\_s3<br/>destination). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked into the optional() fields, so supplying only the required<br/>name, bucket\_arn and role\_arn yields a stream with server-side encryption<br/>(CUSTOMER\_MANAGED\_CMK), KMS-encrypted S3 delivery and CloudWatch error<br/>logging. Insecure choices require flipping an explicit `allow_*` escape hatch.<br/><br/>This atom owns exactly one resource and takes the bucket, role and KMS key as<br/>inputs (ARNs) — it never creates them. Compose it from a component. | <pre>object({<br/>    # --- Required: the caller must decide these. No defaults. -----------------<br/>    name       = string # delivery stream name<br/>    bucket_arn = string # destination S3 bucket ARN (input, not created here)<br/>    role_arn   = string # firehose delivery IAM role ARN (input, not created here)<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) -<br/>    # kms_key_arn drives BOTH the stream's server-side encryption (SSE) and the<br/>    # S3 delivery encryption. null = SSE uses an AWS-owned CMK and S3 delivery<br/>    # falls back to the bucket's own encryption.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Buffering ------------------------------------------------------------<br/>    buffering_size     = optional(number, 5)   # MB, 1-128<br/>    buffering_interval = optional(number, 300) # seconds, 0-900<br/><br/>    # --- S3 delivery layout ---------------------------------------------------<br/>    prefix = optional(string) # null = bucket root prefix<br/><br/>    # --- CloudWatch error logging (PCI DSS Req 10) ----------------------------<br/>    cloudwatch_log_group_name  = optional(string)<br/>    cloudwatch_log_stream_name = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) -------<br/>    # Permits disabling the stream's server-side encryption. The S3-delivery<br/>    # KMS key (kms_key_arn) is independent of this flag.<br/>    allow_unencrypted = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Kinesis Firehose delivery stream atom, collected on a single object. |
<!-- END_TF_DOCS -->