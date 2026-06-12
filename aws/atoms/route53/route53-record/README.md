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
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for a single Route53 record. All inputs live on this single<br/>object. The record is either a STANDARD record (`records` + `ttl`) or an<br/>ALIAS record (`alias` block pointing at an AWS resource) — exactly one of the<br/>two must be supplied.<br/><br/>NOTE: aws\_route53\_record does NOT support tags. `tags` is accepted only so<br/>this atom's config shape matches the rest of the library; it is not applied<br/>to any resource. | <pre>object({<br/>    zone_id = string # required — hosted zone id<br/>    name    = string # required — record name (FQDN or relative to the zone)<br/>    type    = string # required — A | AAAA | CNAME | TXT | MX | NS | SRV | CAA<br/><br/>    ttl     = optional(number, 300)      # standard records only; ignored for alias<br/>    records = optional(list(string), []) # standard records only; ignored for alias<br/><br/>    # Alias record target. When set, ttl/records are omitted (alias record).<br/>    alias = optional(object({<br/>      name                   = string<br/>      zone_id                = string<br/>      evaluate_target_health = optional(bool, true)<br/>    }))<br/><br/>    allow_overwrite = optional(bool, false) # do not clobber existing records by default<br/>    tags            = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Route53 record atom, collected on a single object. |
<!-- END_TF_DOCS -->