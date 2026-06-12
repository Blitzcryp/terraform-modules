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
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the subnet. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields. Required<br/>fields (name, vpc\_id, cidr\_block, availability\_zone) have no default, so<br/>config cannot be omitted. Insecure choices require flipping an explicit<br/>`allow_*` escape hatch. | <pre>object({<br/>    name              = string # required — no default<br/>    vpc_id            = string # required — no default<br/>    cidr_block        = string # required — no default<br/>    availability_zone = string # required — no default<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 1 — no auto public exposure) ---<br/>    map_public_ip_on_launch = optional(bool, false)<br/>    tags                    = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_auto_public_ip = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the subnet atom, collected on a single object. |
<!-- END_TF_DOCS -->