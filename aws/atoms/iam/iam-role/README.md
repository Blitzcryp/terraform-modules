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
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM role. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so the<br/>caller only has to supply the required `assume_role_policy` (who may assume<br/>the role). Insecure choices require flipping an explicit `allow_*` escape<br/>hatch. | <pre>object({<br/>    # assume_role_policy is REQUIRED: the caller MUST declare who can assume the<br/>    # role (PCI DSS Req 7 least privilege, Req 8 identify & authenticate). No<br/>    # safe default exists for "who can become this identity".<br/>    assume_role_policy = string<br/><br/>    name        = optional(string) # if null, derived from name_prefix<br/>    name_prefix = optional(string) # unique name beginning with this prefix; conflicts with name<br/>    description = optional(string, "Managed by terraform (atoms/iam-role)")<br/>    path        = optional(string, "/")<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 7 / Req 8) ---<br/>    permissions_boundary  = optional(string)           # cap the role's maximum effective permissions<br/>    max_session_duration  = optional(number, 3600)     # 3600-43200; limits credential exposure window<br/>    force_detach_policies = optional(bool, true)       # avoid orphaned dangling attachments<br/>    managed_policy_arns   = optional(list(string), []) # managed policy ARNs to attach<br/>    inline_policies       = optional(map(string), {})  # inline policy name => policy JSON<br/>    tags                  = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_admin_policy = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM role atom, collected on a single object. |
<!-- END_TF_DOCS -->