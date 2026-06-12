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
| <a name="module_password_policy"></a> [password\_policy](#module\_password\_policy) | ../../atoms/iam/account-password-policy | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the account-baseline component (account-wide security<br/>guardrails, PCI DSS Req 8 access control). All inputs live on this single<br/>object. PCI-compliant defaults are baked into the optional() fields, so<br/>passing `{}` (or omitting config entirely) yields a compliant baseline. This<br/>component is structured so additional account-level atoms can be composed in<br/>later. Insecure choices require flipping an explicit `allow_*` escape hatch<br/>that is passed down to the underlying atoms.<br/><br/>NOTE: the account password policy is not a taggable AWS resource. `tags` is<br/>accepted for interface uniformity and threaded to atoms that support it. | <pre>object({<br/>    # --- Secure-by-default controls (PCI DSS Req 8.3.6 / 8.3.7 / 8.3.9) ---<br/>    password_minimum_length   = optional(number, 14) # PCI 8.3.6: >= 12<br/>    password_max_age          = optional(number, 90) # PCI 8.3.9: rotate <= 90 days<br/>    password_reuse_prevention = optional(number, 4)  # PCI 8.3.7: >= 4 cycles<br/>    require_symbols           = optional(bool, true) # PCI 8.3.6 complexity<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the account-baseline component, collected on a single object. |
<!-- END_TF_DOCS -->