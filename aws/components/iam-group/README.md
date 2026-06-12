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
| <a name="module_group"></a> [group](#module\_group) | ../../atoms/iam/iam-group | n/a |
| <a name="module_membership"></a> [membership](#module\_membership) | ../../atoms/iam/iam-group-membership | n/a |
| <a name="module_policy_attachment"></a> [policy\_attachment](#module\_policy\_attachment) | ../../atoms/iam/iam-group-policy-attachment | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the iam-group component (an IAM group with attached managed<br/>policies and members). All inputs live on this single object; the caller must<br/>supply the required `name`.<br/><br/>This component is the group-centric place to manage permissions and<br/>membership for human/service users (PCI DSS Req 7 least privilege): attach<br/>managed policies to the group and list the group's members here, rather than<br/>attaching policies or keys to individual users. The membership is managed<br/>EXCLUSIVELY — users not listed in `users` are removed from the group on apply. | <pre>object({<br/>    # name is REQUIRED: the friendly IAM group name. No safe default exists.<br/>    name = string<br/><br/>    path                = optional(string, "/")<br/>    managed_policy_arns = optional(list(string), []) # managed policy ARNs to attach to the group<br/>    users               = optional(list(string), []) # full set of IAM user names that belong to the group<br/>    tags                = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the iam-group component, collected on a single object. |
<!-- END_TF_DOCS -->