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
| [aws_kinesis_stream.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_stream) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Kinesis data stream. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>the caller only has to supply the required `name` to get a KMS-encrypted,<br/>on-demand stream. Insecure choices require flipping an explicit `allow_*`<br/>escape hatch. | <pre>object({<br/>    # name is REQUIRED: the caller must decide the stream name. No default.<br/>    name = string<br/><br/>    # --- Capacity ---<br/>    # stream_mode ON_DEMAND (default) auto-scales and must NOT set shard_count.<br/>    # PROVISIONED requires shard_count.<br/>    stream_mode = optional(string, "ON_DEMAND")<br/>    shard_count = optional(number) # null for ON_DEMAND; required for PROVISIONED<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3: protect stored data) ---<br/>    retention_period = optional(number, 24) # hours, 24-8760<br/>    kms_key_arn      = optional(string)     # BYO CMK; null = AWS-managed kinesis key<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # sets encryption_type = NONE<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Kinesis data stream atom, collected on a single object. |
<!-- END_TF_DOCS -->