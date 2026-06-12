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
| [aws_network_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the network ACL. All inputs live on this single object.<br/>`vpc_id` is required (the caller must decide it). A network ACL is stateless<br/>and DEFAULT-DENY: traffic is dropped unless an explicit numbered rule allows<br/>it, in BOTH directions (return traffic needs its own rule — typically the<br/>ephemeral port range). PCI-DSS-compliant defaults are baked into the<br/>optional() fields: no rules at all (deny everything) until you add them, and<br/>insecure openings require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    vpc_id = string                 # required — the caller must decide this<br/>    name   = optional(string, null) # used only for the Name tag<br/><br/>    # Subnet associations. A subnet may be associated with at most one NACL;<br/>    # associating it here moves it off the VPC's default NACL.<br/>    subnet_ids = optional(list(string), [])<br/><br/>    # --- Rules ----------------------------------------------------------<br/>    #<br/>    # NACL rules are numbered (evaluated low→high, first match wins) and each<br/>    # carries an explicit rule_action ("allow" or "deny") — there is no implicit<br/>    # allow. Each rule targets ONE source/destination (an IPv4 OR IPv6 CIDR).<br/>    # tcp/udp require from_port+to_port; icmp uses icmp_type+icmp_code; "-1"<br/>    # (all protocols) needs neither.<br/>    ingress_rules = optional(list(object({<br/>      rule_number     = number<br/>      protocol        = string<br/>      rule_action     = string<br/>      cidr_block      = optional(string)<br/>      ipv6_cidr_block = optional(string)<br/>      from_port       = optional(number)<br/>      to_port         = optional(number)<br/>      icmp_type       = optional(number)<br/>      icmp_code       = optional(number)<br/>    })), [])<br/><br/>    egress_rules = optional(list(object({<br/>      rule_number     = number<br/>      protocol        = string<br/>      rule_action     = string<br/>      cidr_block      = optional(string)<br/>      ipv6_cidr_block = optional(string)<br/>      from_port       = optional(number)<br/>      to_port         = optional(number)<br/>      icmp_type       = optional(number)<br/>      icmp_code       = optional(number)<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) -<br/>    # Permit an ALLOW rule whose source is the whole internet (0.0.0.0/0 or ::/0).<br/>    allow_public_ingress = optional(bool, false)<br/>    # Permit an ALLOW rule that exposes an admin port (22/SSH, 3389/RDP) to the<br/>    # whole internet.<br/>    allow_public_admin_ports = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the network ACL atom, collected on a single object. |
<!-- END_TF_DOCS -->