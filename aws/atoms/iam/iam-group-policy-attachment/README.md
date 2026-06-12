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
| [aws_iam_group_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_group_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM group policy attachment atom. All inputs live on<br/>this single object — both fields are required.<br/><br/>Attaches a single managed policy to an IAM group (PCI DSS Req 7: grant<br/>permissions to groups, not individual users). This is a non-exclusive<br/>attachment: it manages only this one (group, policy) pair. | <pre>object({<br/>    # Both required: there is no safe default for "which policy on which group".<br/>    group      = string # the IAM group name to attach the policy to<br/>    policy_arn = string # the ARN of the managed policy to attach<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM group policy attachment atom, collected on a single object. |
<!-- END_TF_DOCS -->