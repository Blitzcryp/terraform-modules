<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_user"></a> [user](#module\_user) | ../../atoms/iam/iam-user | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the iam-user component (a single human/service IAM user,<br/>secure by default). All inputs live on this single object; the caller must<br/>supply the required `name`.<br/><br/>SECURITY (PCI DSS Req 8): this component creates ONLY the user identity (plus<br/>an optional permissions boundary). It creates NO static access keys and NO<br/>console login password. Long-lived credentials are discouraged — prefer IAM<br/>roles, SSO, or OIDC/Web Identity federation; any credential must be issued<br/>out-of-band and never committed to source control.<br/><br/>Group membership is NOT managed here: it is managed group-centrically by the<br/>iam-group component (which owns each group's full membership). MFA<br/>enforcement is an org/account-level control, not something this component<br/>fabricates — see the README. | <pre>object({<br/>    # name is REQUIRED: the friendly IAM user name. No safe default exists.<br/>    name = string<br/><br/>    path                 = optional(string, "/")<br/>    permissions_boundary = optional(string) # cap the user's maximum effective permissions (PCI DSS Req 7)<br/>    force_destroy        = optional(bool, false)<br/>    tags                 = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the iam-user component, collected on a single object. |
<!-- END_TF_DOCS -->