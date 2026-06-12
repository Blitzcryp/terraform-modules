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
| <a name="module_certificate"></a> [certificate](#module\_certificate) | ../../atoms/acm/acm-certificate | n/a |
| <a name="module_validation"></a> [validation](#module\_validation) | ../../atoms/acm/acm-certificate-validation | n/a |
| <a name="module_validation_record"></a> [validation\_record](#module\_validation\_record) | ../../atoms/route53/route53-record | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the acm component: a fully DNS-validated, ISSUED ACM<br/>certificate. All inputs live on this single object. Passing the required<br/>`domain_name` and `hosted_zone_id` yields a certificate whose DNS validation<br/>records are created in the supplied Route53 hosted zone and which is waited on<br/>until ACM reports it ISSUED.<br/><br/>This component composes atoms via module blocks:<br/>  - acm/acm-certificate            (requests the DNS-validated cert)<br/>  - route53/route53-record         (one validation CNAME per domain/SAN)<br/>  - acm/acm-certificate-validation (blocks until the cert is ISSUED)<br/><br/>The caller MUST own the hosted zone identified by `hosted_zone_id` and it must<br/>be authoritative for `domain_name` (and every SAN) so ACM can resolve the<br/>validation records. | <pre>object({<br/>    domain_name               = string                     # required — primary FQDN on the cert<br/>    subject_alternative_names = optional(list(string), []) # extra FQDNs (SANs)<br/>    hosted_zone_id            = string                     # required — Route53 zone for validation records<br/>    tags                      = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the acm component, collected on a single object. |
<!-- END_TF_DOCS -->