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
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ACM certificate. All inputs live on this single object.<br/>Secure-by-default values are baked into the optional() fields: DNS validation<br/>(no manual email click-through, fully automatable) and a strong RSA\_2048 key.<br/>Passing only the required `domain_name` yields a DNS-validated certificate.<br/><br/>This atom owns ONLY the certificate request — it does not create the DNS<br/>validation records or wait for issuance. Compose it with the<br/>`route53/route53-record` and `acm/acm-certificate-validation` atoms (see the<br/>`components/acm` component) to obtain a fully validated, ISSUED certificate. | <pre>object({<br/>    domain_name               = string                       # required — primary FQDN on the cert<br/>    subject_alternative_names = optional(list(string), [])   # extra FQDNs (SANs)<br/>    validation_method         = optional(string, "DNS")      # DNS (automatable) or EMAIL<br/>    key_algorithm             = optional(string, "RSA_2048") # key spec<br/>    tags                      = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ACM certificate atom, collected on a single object. |
<!-- END_TF_DOCS -->