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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_flow_log_group"></a> [flow\_log\_group](#module\_flow\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_flow_log_kms"></a> [flow\_log\_kms](#module\_flow\_log\_kms) | ../../atoms/kms/kms-key | n/a |
| <a name="module_flow_log_role"></a> [flow\_log\_role](#module\_flow\_log\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_internet_gateway"></a> [internet\_gateway](#module\_internet\_gateway) | ../../atoms/vpc/internet-gateway | n/a |
| <a name="module_nat_eip"></a> [nat\_eip](#module\_nat\_eip) | ../../atoms/vpc/elastic-ip | n/a |
| <a name="module_nat_gateway"></a> [nat\_gateway](#module\_nat\_gateway) | ../../atoms/vpc/nat-gateway | n/a |
| <a name="module_private_route_table"></a> [private\_route\_table](#module\_private\_route\_table) | ../../atoms/vpc/route-table | n/a |
| <a name="module_public_route_table"></a> [public\_route\_table](#module\_public\_route\_table) | ../../atoms/vpc/route-table | n/a |
| <a name="module_subnet"></a> [subnet](#module\_subnet) | ../../atoms/vpc/subnet | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../atoms/vpc/vpc | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the secure-network component. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields: flow logs are ON by default and subnets are private by default.<br/>Required fields (name, cidr\_block, subnets) have no default, so config<br/>cannot be omitted. Insecure choices require flipping an explicit `allow_*`<br/>escape hatch. | <pre>object({<br/>    name       = string # required — no default<br/>    cidr_block = string # required — no default<br/><br/>    # One object per subnet. Subnets are PRIVATE by default (public=false);<br/>    # making a subnet public is an intentional, auditable choice.<br/>    subnets = list(object({<br/>      name              = string<br/>      cidr_block        = string<br/>      availability_zone = string<br/>      public            = optional(bool, false)<br/>    }))<br/><br/>    # --- Routing (additive) -----------------------------------------------<br/>    # Internet gateway: null = auto (created iff any subnet is public). Set<br/>    # true/false to force on/off.<br/>    enable_internet_gateway = optional(bool)<br/><br/>    # NAT gateway strategy for private-subnet egress:<br/>    #   "none"   = no NAT (private subnets get no default route)<br/>    #   "single" = one NAT in the first public subnet (cheaper, single-AZ)<br/>    #   "per_az" = one NAT per AZ that has a public subnet (HA, per-AZ private<br/>    #              route tables)<br/>    nat_gateway_mode = optional(string, "single")<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 10 logging) ---<br/>    enable_flow_logs           = optional(bool, true)  # PCI DSS Req 10<br/>    flow_log_retention_in_days = optional(number, 365) # >= 1 year audit retention<br/><br/>    # Bring-your-own flow-log sink. When BOTH are provided, the component wires<br/>    # them into the VPC and does NOT self-provision kms/log-group/iam-role<br/>    # (e.g. inject a central log group + role from the audit-logging component).<br/>    byo_flow_log_destination_arn = optional(string)<br/>    byo_flow_log_role_arn        = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Forwarded to the vpc atom: permits enable_flow_logs=false.<br/>    allow_flow_logs_disabled = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the secure-network component, collected on a single object. |
<!-- END_TF_DOCS -->