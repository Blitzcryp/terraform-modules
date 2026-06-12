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
| [aws_iam_account_password_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the account IAM password policy (PCI DSS Req 8: identify &<br/>authenticate access). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked into the optional() fields, so passing `{}` (or omitting<br/>config entirely) yields a compliant policy: 14-char minimum, full character<br/>complexity, 4-cycle reuse prevention and 90-day rotation. This is an<br/>account-level singleton — there is no required field. Insecure choices<br/>require flipping an explicit `allow_*` escape hatch.<br/><br/>NOTE: aws\_iam\_account\_password\_policy does NOT support tags. `tags` is<br/>accepted only so this atom's config shape matches the rest of the library;<br/>it is not applied to any resource. | <pre>object({<br/>    # --- Secure-by-default controls (PCI DSS Req 8.3.6 / 8.3.7 / 8.3.9) ---<br/>    minimum_password_length        = optional(number, 14) # PCI 8.3.6: >= 12<br/>    require_lowercase_characters   = optional(bool, true) # PCI 8.3.6 complexity<br/>    require_uppercase_characters   = optional(bool, true) # PCI 8.3.6 complexity<br/>    require_numbers                = optional(bool, true) # PCI 8.3.6 complexity<br/>    require_symbols                = optional(bool, true) # PCI 8.3.6 complexity<br/>    password_reuse_prevention      = optional(number, 4)  # PCI 8.3.7: >= 4 cycles<br/>    max_password_age               = optional(number, 90) # PCI 8.3.9: rotate <= 90 days<br/>    allow_users_to_change_password = optional(bool, true)<br/>    hard_expiry                    = optional(bool, false) # do not lock out expired users by default<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Permit minimum_password_length below the PCI 8.3.6 floor of 12.<br/>    allow_short_password = optional(bool, false)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the account password policy atom, collected on a single object. |
<!-- END_TF_DOCS -->