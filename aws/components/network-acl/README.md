# network-acl

A configured subnet-level **network ACL** (stateless firewall) for one network
tier. Composes the `vpc/network-acl` atom. NACLs are **stateless** and
**default-deny**, so they add subnet-boundary defense-in-depth on top of
security groups (PCI DSS Req 1).

## Key facts about NACLs

- **Stateless** — return traffic is NOT automatically allowed. Every connection
  needs a rule in each direction. Responses to outbound/inbound connections
  arrive on the **ephemeral port range** (`1024-65535`), so that range is opened
  explicitly in the opposite direction.
- **Numbered & ordered** — rules are evaluated low→high `rule_number`, first
  match wins. Leave gaps (100, 110, 120…) so rules can be inserted later.
- **Default-deny** — the implicit, un-removable final rule denies everything not
  explicitly allowed. A NACL with no rules denies all traffic.
- **One NACL per subnet** — associating a subnet here moves it off the VPC's
  default NACL.

## Secure by default

- No rules are created until you add them (deny everything).
- An ingress `allow` rule open to `0.0.0.0/0` / `::/0` is rejected unless
  `allow_public_ingress = true`.
- Such a rule that also exposes an **admin port** (22/SSH, 3389/RDP) is rejected
  unless `allow_public_admin_ports = true`.
- Both escape hatches are grep-able and pass straight through to the atom. File
  a PCI exception (security@emag.ro) before flipping either.

## Recommended per-tier baselines

These are starting points — tighten to your actual flows.

### Private tier (app/data subnets, no inbound from the internet)

Allow VPC-internal traffic both ways, plus the ephemeral return range scoped to
the VPC CIDR. Everything else falls through to the implicit deny.

```hcl
ingress_rules = [
  { rule_number = 100, protocol = "-1",  rule_action = "allow", cidr_block = "10.0.0.0/16" },
  { rule_number = 110, protocol = "tcp", rule_action = "allow", cidr_block = "10.0.0.0/16", from_port = 1024, to_port = 65535 },
]
egress_rules = [
  { rule_number = 100, protocol = "-1",  rule_action = "allow", cidr_block = "10.0.0.0/16" },
  { rule_number = 110, protocol = "tcp", rule_action = "allow", cidr_block = "10.0.0.0/16", from_port = 1024, to_port = 65535 },
]
```

### Public/web tier (terminates internet HTTPS)

Allow inbound 443 from the internet plus the ephemeral return range; allow
outbound 443 plus the ephemeral return range. Because inbound 443 is from
`0.0.0.0/0` (not an admin port), set `allow_public_ingress = true`. Never open
22/3389 to the internet — use a bastion / SSM Session Manager instead.

```hcl
allow_public_ingress = true   # 443 from the internet is intentional
ingress_rules = [
  { rule_number = 100, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 443,  to_port = 443 },
  { rule_number = 110, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 1024, to_port = 65535 },
]
egress_rules = [
  { rule_number = 100, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 443,  to_port = 443 },
  { rule_number = 110, protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 1024, to_port = 65535 },
]
```

## PCI DSS controls

| Requirement | How this module satisfies it |
| ----------- | ---------------------------- |
| Req 1.2 / 1.3 | Subnet-level stateless firewall; default-deny, explicit numbered allow rules only — restricts traffic between trust zones. |
| Req 1 (defense-in-depth) | Independent enforcement layer beneath security groups. |
| Req 1.1.x | Every rule carries an explicit `rule_action`; public/admin openings require a documented, grep-able exception. |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_network_acl"></a> [network\_acl](#module\_network\_acl) | ../../atoms/vpc/network-acl | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the network-acl component: a configured subnet-level<br/>stateless firewall for one network tier (e.g. a private tier). `name` and<br/>`vpc_id` are required. A network ACL is DEFAULT-DENY and STATELESS — every<br/>opening is an explicit numbered rule, and return traffic needs its own rule<br/>(typically the ephemeral port range 1024-65535). PCI-DSS-compliant defaults:<br/>no rules until you add them (deny everything), and any opening to the public<br/>internet requires flipping an explicit `allow_*` escape hatch (passthrough to<br/>the underlying atom). See the README for recommended per-tier baselines. | <pre>object({<br/>    name   = string # required — the caller must decide this<br/>    vpc_id = string # required — the caller must decide this<br/><br/>    # Subnets this tier's NACL is associated with (moves them off the default NACL).<br/>    subnet_ids = optional(list(string), [])<br/><br/>    # Numbered, explicit-action rules. See the atom for field semantics:<br/>    # tcp/udp need from_port+to_port; icmp uses icmp_type+icmp_code; "-1" needs<br/>    # neither; each rule sets exactly one of cidr_block / ipv6_cidr_block.<br/>    ingress_rules = optional(list(object({<br/>      rule_number     = number<br/>      protocol        = string<br/>      rule_action     = string<br/>      cidr_block      = optional(string)<br/>      ipv6_cidr_block = optional(string)<br/>      from_port       = optional(number)<br/>      to_port         = optional(number)<br/>      icmp_type       = optional(number)<br/>      icmp_code       = optional(number)<br/>    })), [])<br/><br/>    egress_rules = optional(list(object({<br/>      rule_number     = number<br/>      protocol        = string<br/>      rule_action     = string<br/>      cidr_block      = optional(string)<br/>      ipv6_cidr_block = optional(string)<br/>      from_port       = optional(number)<br/>      to_port         = optional(number)<br/>      icmp_type       = optional(number)<br/>      icmp_code       = optional(number)<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (passthrough to the atom) ----------------------<br/>    allow_public_ingress     = optional(bool, false)<br/>    allow_public_admin_ports = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the network-acl component, collected on a single object. |
<!-- END_TF_DOCS -->