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
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the IAM managed policy. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>the caller only has to supply the required `name` and `policy` document.<br/>Insecure choices require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    # name is REQUIRED: the caller must decide the policy's identity.<br/>    name = string<br/>    # policy is REQUIRED: the policy document (JSON string). No safe default<br/>    # exists for "what permissions does this grant" (PCI DSS Req 7).<br/>    policy = string<br/><br/>    description = optional(string, "Managed by terraform (atoms/iam-policy)")<br/>    path        = optional(string, "/")<br/>    tags        = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_admin_policy = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the IAM policy atom, collected on a single object. |
<!-- END_TF_DOCS -->