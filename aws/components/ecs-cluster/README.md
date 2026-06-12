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
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ../../atoms/ecs/ecs-cluster | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ecs-cluster component (a Fargate ECS cluster with<br/>encrypted ECS Exec / container audit logging). All inputs live on this single<br/>object. PCI-compliant defaults are baked into the optional() fields, so the<br/>caller only has to supply the required `name`: Container Insights on, a<br/>CloudWatch-Logs-authorised CMK created when no BYO key is supplied, an<br/>encrypted log group with 365-day retention, and Fargate-only capacity. | <pre>object({<br/>    # name is REQUIRED: the cluster name (also used for the log group and KMS<br/>    # alias). The caller must decide it. No default.<br/>    name = string<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption, Req 10 logging) ---<br/>    # BYOK: if set, no kms-key atom is created and this key encrypts the log group<br/>    # and ECS Exec sessions. Otherwise the component owns a CMK.<br/>    kms_key_arn = optional(string)<br/><br/>    log_retention_days = optional(number, 365) # >= 1 year of audit logs<br/><br/>    # Fargate-only capacity by default (no unmanaged EC2 capacity to patch).<br/>    capacity_providers = optional(list(string), ["FARGATE", "FARGATE_SPOT"])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ecs-cluster component, collected on a single object. |
<!-- END_TF_DOCS -->