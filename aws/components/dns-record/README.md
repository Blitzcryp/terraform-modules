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
| <a name="module_record"></a> [record](#module\_record) | ../../atoms/route53/route53-record | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the dns-record component: point one or more DNS names at<br/>AWS resources (or arbitrary values) within a single Route53 hosted zone. All<br/>inputs live on this single object.<br/><br/>Each entry in `records` is either a STANDARD record (set `values`, leave<br/>`alias` null) or an ALIAS record (set `alias`, leave `values` empty) — the<br/>underlying route53-record atom enforces exactly-one-of. Alias records are how<br/>you point an apex/subdomain at an ALB, CloudFront distribution, or S3 website.<br/><br/>This component composes the route53/route53-record atom via module blocks —<br/>one instance per record.<br/><br/>NOTE: aws\_route53\_record does not support tags. `tags` is accepted for<br/>library uniformity but is not applied to any resource. | <pre>object({<br/>    zone_id = string # required — the hosted zone all records are created in<br/><br/>    records = list(object({<br/>      name   = string<br/>      type   = optional(string, "A")<br/>      ttl    = optional(number, 300)      # standard records only; ignored for alias<br/>      values = optional(list(string), []) # standard records only<br/>      alias = optional(object({           # alias records only<br/>        name                   = string<br/>        zone_id                = string<br/>        evaluate_target_health = optional(bool, true)<br/>      }))<br/>    })) # required — at least one record<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the dns-record component, collected on a single object. |
<!-- END_TF_DOCS -->