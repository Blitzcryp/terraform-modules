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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_backup_role"></a> [backup\_role](#module\_backup\_role) | ../../atoms/iam/iam-role | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_plan"></a> [plan](#module\_plan) | ../../atoms/backup/backup-plan | n/a |
| <a name="module_selection"></a> [selection](#module\_selection) | ../../atoms/backup/backup-selection | n/a |
| <a name="module_vault"></a> [vault](#module\_vault) | ../../atoms/backup/backup-vault | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the backup component (PCI DSS Req 9/10/12: encrypted,<br/>optionally immutable backups with enforced retention). All inputs live on<br/>this single object. PCI-compliant defaults are baked into the optional()<br/>fields, so the caller only has to supply the required `name`:<br/>  - a customer-managed CMK is created (usable by AWS Backup) unless a BYO<br/>    kms\_key\_arn is supplied,<br/>  - a daily backup plan with 35-day retention is created,<br/>  - every resource tagged Backup=true is selected for backup,<br/>  - a least-privilege AWS Backup service role is created. | <pre>object({<br/>    # name is REQUIRED: base name for the vault, plan, selection, role and KMS<br/>    # alias. The caller must decide it. No default.<br/>    name = string<br/><br/>    # --- Encryption (PCI DSS Req 3) ------------------------------------------<br/>    # BYO CMK ARN. When null the component creates a CMK authorised for AWS Backup.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Backup schedule & retention (PCI DSS Req 10.5.1 / Req 12) -----------<br/>    schedule                = optional(string, "cron(0 5 * * ? *)") # daily 05:00 UTC<br/>    start_window            = optional(number, 60)                  # minutes<br/>    completion_window       = optional(number, 180)                 # minutes<br/>    cold_storage_after_days = optional(number)                      # null = never<br/>    delete_after_days       = optional(number, 35)                  # retention<br/><br/>    # --- Vault Lock (WORM immutability, PCI DSS Req 10.5 / Req 12) ------------<br/>    enable_vault_lock  = optional(bool, false)<br/>    lock_mode          = optional(string, "governance")<br/>    min_retention_days = optional(number)<br/>    max_retention_days = optional(number)<br/><br/>    # --- What to back up ------------------------------------------------------<br/>    # Tag-based selection (default: every resource tagged Backup=true). Rendered<br/>    # as STRINGEQUALS selection tags. Combine with explicit resource_arns.<br/>    selection_tags = optional(map(string), { Backup = "true" })<br/>    resource_arns  = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the backup component, collected on a single object. |
<!-- END_TF_DOCS -->