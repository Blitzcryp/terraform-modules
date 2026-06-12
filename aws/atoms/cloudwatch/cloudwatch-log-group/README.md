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
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the CloudWatch log group. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>the caller only has to supply the required `name`. Insecure choices require<br/>flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    # name is REQUIRED: the caller must decide the log group name. No default.<br/>    name = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 retention) ---<br/>    kms_key_arn       = optional(string)      # null is rejected unless allow_unencrypted=true<br/>    retention_in_days = optional(number, 365) # 365 keeps audit logs >= 1 year; 0 requires allow_no_retention<br/>    log_group_class   = optional(string, "STANDARD")<br/>    skip_destroy      = optional(bool, false)<br/>    tags              = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted  = optional(bool, false)<br/>    allow_no_retention = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CloudWatch log group atom, collected on a single object. |
<!-- END_TF_DOCS -->