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
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_parameter"></a> [parameter](#module\_parameter) | ../../atoms/ssm/ssm-parameter | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ssm-parameters component (a set of encrypted<br/>parameters). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked in: every parameter is a SecureString encrypted with a<br/>customer-managed KMS key (Req 3 / Req 8).<br/><br/>This component composes atoms via module blocks: a kms-key atom (the CMK that<br/>encrypts every parameter — created unless a `kms_key_arn` is supplied) and<br/>one ssm-parameter atom per entry in the `parameters` map.<br/><br/>SECURITY: parameter VALUES must never be hardcoded secrets in source control.<br/>Supply them out-of-band (CI/CD secret store) and use <YOUR\_PARAMETER\_VALUE><br/>placeholders in examples (PCI DSS Req 3 / Req 8). | <pre>object({<br/>    # --- Required: prefix for every parameter name and the CMK alias. ---<br/>    name_prefix = string<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYOK: when set, the supplied CMK encrypts all parameters and no kms-key<br/>    # atom is created. When null, a dedicated kms-key atom is created.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- The parameters to manage. Keyed by logical name; the full parameter<br/>    # name is "${name_prefix}/${key}". Every parameter is a SecureString. ---<br/>    parameters = optional(map(object({<br/>      value       = string # SECURITY: never hardcode a real secret here<br/>      description = optional(string)<br/>      tier        = optional(string, "Standard")<br/>    })), {})<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ssm-parameters component, collected on a single object. |
<!-- END_TF_DOCS -->