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
| [aws_ssm_parameter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the SSM Parameter Store atom. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields: the parameter is a SecureString encrypted with a customer-managed<br/>KMS key (Req 3 / Req 8). Storing plaintext (String/StringList) requires<br/>flipping the explicit `allow_plaintext` escape hatch.<br/><br/>SECURITY: the parameter VALUE must never be a hardcoded secret in source<br/>control. Supply it from a secrets source / CI variable and use a<br/><YOUR\_PARAMETER\_VALUE> placeholder in examples (PCI DSS Req 3 / Req 8). | <pre>object({<br/>    # --- Required ---<br/>    name  = string<br/>    value = string # SECURITY: never hardcode a real secret here<br/><br/>    # --- Type (PCI DSS Req 3): SecureString by default ---<br/>    type = optional(string, "SecureString") # String | StringList | SecureString<br/><br/>    # --- Encryption: CMK used to encrypt a SecureString (Req 3). ---<br/>    kms_key_arn = optional(string)<br/><br/>    description = optional(string)<br/>    tier        = optional(string, "Standard") # Standard | Advanced | Intelligent-Tiering<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatch: permit plaintext String/StringList (no encryption). ---<br/>    allow_plaintext = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the SSM parameter atom, collected on a single object. |
<!-- END_TF_DOCS -->