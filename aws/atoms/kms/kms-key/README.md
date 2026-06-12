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
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the KMS key. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so passing<br/>`{}` (or omitting config entirely) yields a compliant key. Insecure choices<br/>require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    description = optional(string, "Managed by terraform (atoms/kms-key)")<br/>    alias       = optional(string) # without the 'alias/' prefix; null = no alias<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3: protect stored data) ---<br/>    enable_key_rotation     = optional(bool, true) # PCI 3.6.4 / 3.7<br/>    deletion_window_in_days = optional(number, 30) # 7-30; longer = safer<br/>    multi_region            = optional(bool, false)<br/>    key_usage               = optional(string, "ENCRYPT_DECRYPT")<br/>    key_spec                = optional(string, "SYMMETRIC_DEFAULT")<br/>    policy                  = optional(string) # null = least-privilege default policy<br/>    tags                    = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_rotation_disabled = optional(bool, false)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the KMS key atom, collected on a single object. |
<!-- END_TF_DOCS -->