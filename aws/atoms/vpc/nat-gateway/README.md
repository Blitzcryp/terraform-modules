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
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the NAT gateway. All inputs live on this single object.<br/>A public NAT gateway lives in a PUBLIC subnet and uses an Elastic IP<br/>allocation; both are inputs (this atom does not create the subnet or EIP).<br/>Required fields (subnet\_id, allocation\_id) have no default. | <pre>object({<br/>    subnet_id         = string           # required — public subnet for the NAT<br/>    allocation_id     = string           # required — EIP allocation id<br/>    name              = optional(string) # null = no Name tag override<br/>    connectivity_type = optional(string, "public")<br/>    tags              = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the nat-gateway atom, collected on a single object. |
<!-- END_TF_DOCS -->