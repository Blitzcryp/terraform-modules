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
| [aws_iam_group_membership.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_membership) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM group membership atom. All inputs live on this<br/>single object — all three fields are required.<br/><br/>IMPORTANT: aws\_iam\_group\_membership manages the group's FULL membership<br/>exclusively. Any user in the group that is not listed in `users` will be<br/>REMOVED on apply. There is exactly one membership resource per group. | <pre>object({<br/>    # All required: there is no safe default for "who belongs to this group".<br/>    name  = string       # the membership resource name (identifier for this attachment)<br/>    group = string       # the IAM group name to manage membership of<br/>    users = list(string) # the complete set of IAM user names in the group<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM group membership atom, collected on a single object. |
<!-- END_TF_DOCS -->