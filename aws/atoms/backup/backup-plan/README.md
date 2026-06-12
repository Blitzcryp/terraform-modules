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
| [aws_backup_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the AWS Backup plan atom. All inputs live on this single<br/>object. A plan is a set of rules (schedule + retention lifecycle) that drive<br/>when recovery points are taken and how long they are kept (PCI DSS Req 10/12).<br/>PCI-compliant defaults (daily schedule, 35-day retention) are baked into the<br/>rule's optional() fields. | <pre>object({<br/>    # name is REQUIRED: the caller must decide the plan name. No default.<br/>    name = string<br/><br/>    # rules is REQUIRED: a plan must have at least one backup rule.<br/>    rules = list(object({<br/>      rule_name         = string<br/>      target_vault_name = string<br/>      schedule          = optional(string, "cron(0 5 * * ? *)") # daily at 05:00 UTC<br/>      start_window      = optional(number, 60)                  # minutes<br/>      completion_window = optional(number, 180)                 # minutes<br/>      # Lifecycle (PCI DSS Req 10.5.1 retention): days before cold storage / delete.<br/>      cold_storage_after = optional(number) # null = never transition to cold storage<br/>      delete_after       = optional(number, 35)<br/>      # Cross-region/cross-account copy target (DR). null = no copy action.<br/>      copy_action_destination_vault_arn = optional(string)<br/>    }))<br/><br/>    # Pass-through for plugin-specific options (e.g. Windows VSS). Defaults empty.<br/>    advanced_backup_settings = optional(any, [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the AWS Backup plan atom, collected on a single object. |
<!-- END_TF_DOCS -->