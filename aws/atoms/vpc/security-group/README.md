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
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the security group. All inputs live on this single object.<br/>`name` and `vpc_id` are required (the caller must decide them). PCI-DSS-compliant<br/>defaults are baked into the optional() fields: no public ingress, no implicit<br/>allow-all egress. Insecure choices require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name        = string # required — the caller must decide this<br/>    vpc_id      = string # required — the caller must decide this<br/>    description = optional(string, "Managed by terraform (atoms/security-group)")<br/><br/>    # --- Rules ----------------------------------------------------------<br/>    #<br/>    # Each rule targets EXACTLY ONE source/destination: an IPv4 CIDR, an IPv6<br/>    # CIDR, a referenced security group, or a managed prefix list. `description`<br/>    # is REQUIRED on every rule so each opening is documented (PCI DSS Req 1.1.x).<br/>    ingress_rules = optional(list(object({<br/>      description                  = string<br/>      ip_protocol                  = string<br/>      from_port                    = optional(number)<br/>      to_port                      = optional(number)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      prefix_list_id               = optional(string)<br/>    })), [])<br/><br/>    egress_rules = optional(list(object({<br/>      description                  = string<br/>      ip_protocol                  = string<br/>      from_port                    = optional(number)<br/>      to_port                      = optional(number)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      prefix_list_id               = optional(string)<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) -<br/>    allow_public_ingress     = optional(bool, false)<br/>    allow_public_admin_ports = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the security group atom, collected on a single object. |
<!-- END_TF_DOCS -->