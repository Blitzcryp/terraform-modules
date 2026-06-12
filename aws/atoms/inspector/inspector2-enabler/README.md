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
| [aws_inspector2_enabler.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Amazon Inspector v2 enabler. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so passing `{}` (or omitting config entirely) enables continuous<br/>vulnerability scanning for ECR, EC2 and Lambda in the current account<br/>(PCI DSS Req 6 & Req 11). | <pre>object({<br/>    # PCI DSS Req 6/11: scan these resource types for vulnerabilities.<br/>    resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])<br/>    # Accounts to enable Inspector for. Empty = the current account.<br/>    account_ids = optional(list(string), [])<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Inspector v2 enabler atom, collected on a single object. |
<!-- END_TF_DOCS -->