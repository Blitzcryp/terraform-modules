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
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ACM certificate validation. All inputs live on this<br/>single object. This atom does not create AWS resources — it blocks `apply`<br/>until ACM reports the referenced certificate as ISSUED, after the supplied<br/>DNS validation record FQDNs have been published.<br/><br/>Compose it with the `acm/acm-certificate` and `route53/route53-record` atoms:<br/>create the cert, publish its domain\_validation\_options as DNS records, then<br/>feed those record FQDNs here (see the `components/acm` component). | <pre>object({<br/>    certificate_arn         = string                     # required — ARN of the acm-certificate to validate<br/>    validation_record_fqdns = optional(list(string), []) # FQDNs of the published DNS validation records<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ACM certificate validation atom, collected on a single object. |
<!-- END_TF_DOCS -->