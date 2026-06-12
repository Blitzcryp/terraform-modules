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
| [aws_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the route table. All inputs live on this single object.<br/>This atom owns the route table plus its tightly-coupled routes and subnet<br/>associations (meaningless on their own). Each route must specify exactly one<br/>target (gateway\_id, nat\_gateway\_id, or vpc\_endpoint\_id). Required field<br/>(vpc\_id) has no default, so config cannot be omitted. | <pre>object({<br/>    vpc_id = string           # required — no default<br/>    name   = optional(string) # null = no Name tag override<br/><br/>    # Routes added to the table. Each must set exactly one target.<br/>    routes = optional(list(object({<br/>      cidr_block      = string<br/>      gateway_id      = optional(string)<br/>      nat_gateway_id  = optional(string)<br/>      vpc_endpoint_id = optional(string)<br/>    })), [])<br/><br/>    # Subnets associated to this route table.<br/>    subnet_ids = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the route-table atom, collected on a single object. |
<!-- END_TF_DOCS -->