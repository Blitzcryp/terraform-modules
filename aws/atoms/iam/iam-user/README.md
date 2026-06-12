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
| [aws_iam_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM user atom. All inputs live on this single object.<br/>The caller must supply the required `name`. PCI-DSS-compliant defaults are<br/>baked into the optional() fields.<br/><br/>SECURITY (PCI DSS Req 8): this atom creates ONLY the user identity (and an<br/>optional permissions boundary). It deliberately creates NO long-lived static<br/>access keys and NO console login profile/password. Long-lived credentials are<br/>discouraged — prefer IAM roles, SSO, or OIDC/Web Identity federation. If a<br/>credential is unavoidable it must be issued out-of-band (e.g. console, CLI,<br/>or a secrets manager) and NEVER committed to source control. | <pre>object({<br/>    # name is REQUIRED: the friendly IAM user name. No safe default exists.<br/>    name = string<br/><br/>    path                 = optional(string, "/")<br/>    permissions_boundary = optional(string)      # cap the user's maximum effective permissions (PCI DSS Req 7)<br/>    force_destroy        = optional(bool, false) # delete the user even if it has non-Terraform-managed attachments<br/>    tags                 = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM user atom, collected on a single object. |
<!-- END_TF_DOCS -->