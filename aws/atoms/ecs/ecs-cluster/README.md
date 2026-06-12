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
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ECS cluster. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so passing<br/>only the required `name` yields a compliant cluster (Container Insights on,<br/>encrypted ECS Exec audit logging when a KMS key + log group are supplied).<br/>Insecure choices require flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name = string # required — cluster name<br/><br/>    # --- Secure-by-default controls ---<br/>    # Container Insights = observability/monitoring (PCI DSS Req 10: track & monitor access).<br/>    enable_container_insights = optional(bool, true)<br/><br/>    # ECS Exec audit logging to CloudWatch, encrypted with a CMK (PCI DSS Req 10 / Req 3).<br/>    # When both kms_key_arn and execute_command_log_group_name are set, exec sessions are<br/>    # logged to CloudWatch with cloud_watch_encryption_enabled = true.<br/>    kms_key_arn                    = optional(string) # CMK ARN for ECS Exec session encryption<br/>    execute_command_log_group_name = optional(string) # CloudWatch log group for ECS Exec audit logs<br/><br/>    # Fargate-only capacity by default (no unmanaged EC2 capacity to patch — Req 6/2).<br/>    capacity_providers = optional(list(string), ["FARGATE", "FARGATE_SPOT"])<br/>    default_capacity_provider_strategy = optional(list(object({<br/>      capacity_provider = string<br/>      base              = optional(number)<br/>      weight            = optional(number)<br/>    })), [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # Disabling Container Insights removes monitoring telemetry; requires a PCI exception.<br/>    allow_container_insights_disabled = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ECS cluster atom, collected on a single object. |
<!-- END_TF_DOCS -->