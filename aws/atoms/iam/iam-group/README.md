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
| [aws_iam_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM group atom. All inputs live on this single object.<br/>The caller must supply the required `name`. PCI-DSS-compliant defaults are<br/>baked into the optional() fields.<br/><br/>A group is the recommended way to grant permissions to human users (PCI DSS<br/>Req 7 least privilege): attach policies to the group and add users to it,<br/>rather than attaching policies directly to individual users. | <pre>object({<br/>    # name is REQUIRED: the friendly IAM group name. No safe default exists.<br/>    name = string<br/><br/>    path = optional(string, "/")<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM group atom, collected on a single object. |
<!-- END_TF_DOCS -->