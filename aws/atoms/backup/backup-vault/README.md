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
| [aws_backup_vault.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the AWS Backup vault atom. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>the caller only has to supply the required `name`. Insecure choices (a vault<br/>without a customer-managed CMK) require flipping an explicit `allow_*` escape<br/>hatch.<br/><br/>Optional Vault Lock (WORM immutability, PCI DSS Req 9/10/12) is configured on<br/>the same object and rendered as a tightly-coupled<br/>aws\_backup\_vault\_lock\_configuration sub-resource. | <pre>object({<br/>    # name is REQUIRED: the caller must decide the vault name. No default.<br/>    name = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3: protect stored data) ---<br/>    # KMS CMK encrypting recovery points. When null AWS Backup falls back to an<br/>    # AWS-managed key, which is only permitted when allow_unencrypted = true.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Vault Lock (WORM immutability, PCI DSS Req 10.5 / Req 12) -------------<br/>    # governance: can be removed by a principal with sufficient IAM permissions.<br/>    # compliance: immutable — cannot be changed or deleted after the<br/>    #             changeable_for_days cooling-off window elapses.<br/>    enable_lock        = optional(bool, false)<br/>    lock_mode          = optional(string, "governance")<br/>    min_retention_days = optional(number)<br/>    max_retention_days = optional(number)<br/>    # Compliance-mode cooling-off: the vault lock can still be removed within<br/>    # this many days; afterwards it is permanently immutable. Only applied in<br/>    # compliance mode (its presence is what selects compliance mode).<br/>    changeable_for_days = optional(number, 3)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Permit a vault without a customer-managed CMK (AWS-managed key fallback).<br/>    allow_unencrypted = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the AWS Backup vault atom, collected on a single object. |
<!-- END_TF_DOCS -->