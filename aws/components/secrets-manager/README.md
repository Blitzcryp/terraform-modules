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
| <a name="module_secret"></a> [secret](#module\_secret) | ../../atoms/secretsmanager/secretsmanager-secret | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the secrets-manager component (the "Vault" capability).<br/>All inputs live on this single object. PCI-DSS-compliant defaults are baked<br/>into the optional() fields: every secret is encrypted with a customer-managed<br/>KMS key (Req 3) and uses a 30-day recovery window.<br/><br/>This component composes atoms via module blocks: a kms-key atom (the CMK that<br/>encrypts the secrets — created unless a `kms_key_arn` is supplied) and one<br/>secretsmanager-secret atom per entry in the `secrets` map.<br/><br/>SECURITY: This component never sets secret VALUES. Secret material is<br/>populated out-of-band by a secrets source or a rotation Lambda — never<br/>committed to source control (PCI DSS Req 3.5 / Req 8). | <pre>object({<br/>    # --- Required: prefix for every secret name and the CMK alias. ---<br/>    name_prefix = string<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYOK: when set, the supplied CMK encrypts all secrets and no kms-key atom<br/>    # is created. When null, a dedicated kms-key atom is created for this vault.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- The secrets to manage. Keyed by logical name; the full secret name is<br/>    # "${name_prefix}/${key}". Values are NEVER set here. ---<br/>    secrets = optional(map(object({<br/>      description         = optional(string)<br/>      rotation_lambda_arn = optional(string)<br/>      rotation_days       = optional(number, 30)<br/>      policy              = optional(string)<br/>    })), {})<br/><br/>    # --- Deletion safety applied to every secret. 7-30 days. ---<br/>    recovery_window_in_days = optional(number, 30)<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the secrets-manager component, collected on a single object. |
<!-- END_TF_DOCS -->