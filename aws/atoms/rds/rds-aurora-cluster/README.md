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
| [aws_rds_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Aurora cluster. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields, so passing<br/>only the required fields yields a compliant cluster. Insecure choices require<br/>flipping an explicit `allow_*` escape hatch (grep-able, auditable). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    cluster_identifier     = string       # required — cluster name<br/>    db_subnet_group_name   = string       # required — where the cluster lives<br/>    vpc_security_group_ids = list(string) # required — network exposure<br/><br/>    # --- Engine ---<br/>    engine      = optional(string, "aurora-postgresql")<br/>    engine_mode = optional(string, "provisioned")<br/><br/>    # --- Encryption at rest (PCI DSS Req 3: protect stored data) ---<br/>    # storage_encrypted snapshots inherit the cluster's encryption automatically.<br/>    storage_encrypted = optional(bool, true)<br/>    kms_key_arn       = optional(string) # feeds kms_key_id; null = AWS-managed aws/rds key<br/><br/>    # --- Master credentials (PCI DSS Req 8: authenticate access) ---<br/>    # COMPLIANCE: we NEVER accept a plaintext master_password. Static creds in<br/>    # state/config violate PCI Req 8.2.1 (no clear-text). The password is created<br/>    # and rotated in AWS Secrets Manager via manage_master_user_password.<br/>    manage_master_user_password   = optional(bool, true)<br/>    master_username               = optional(string, "dbadmin")<br/>    master_user_secret_kms_key_id = optional(string) # KMS key for the managed secret<br/><br/>    # --- Authentication (PCI DSS Req 8) ---<br/>    iam_database_authentication_enabled = optional(bool, true)<br/><br/>    # --- Backups (PCI DSS Req 10 / resilience: retained for forensics) ---<br/>    backup_retention_period = optional(number, 14) # 7..35<br/>    copy_tags_to_snapshot   = optional(bool, true)<br/><br/>    # --- Deletion safety ---<br/>    deletion_protection = optional(bool, true)<br/><br/>    # --- Logging (PCI DSS Req 10: audit trails) ---<br/>    # null => engine-appropriate default (postgresql vs the mysql audit set).<br/>    enabled_cloudwatch_logs_exports = optional(list(string))<br/><br/>    # --- Windows ---<br/>    preferred_backup_window      = optional(string) # e.g. "02:00-03:00" (UTC)<br/>    preferred_maintenance_window = optional(string) # e.g. "sun:03:30-sun:04:30"<br/><br/>    # --- Serverless v2 (optional use-case). When set, instances must use<br/>    #     instance_class = "db.serverless". ---<br/>    serverlessv2_scaling_configuration = optional(object({<br/>      min_capacity = number<br/>      max_capacity = number<br/>    }))<br/><br/>    # --- Instances ---<br/>    instance_count                  = optional(number, 2)<br/>    instance_class                  = optional(string, "db.r6g.large")<br/>    performance_insights_enabled    = optional(bool, true)<br/>    performance_insights_kms_key_id = optional(string)<br/><br/>    # Patch hygiene: pull in minor engine fixes automatically (PCI DSS Req 6).<br/>    auto_minor_version_upgrade = optional(bool, true)<br/><br/>    # Enhanced monitoring (PCI DSS Req 10). 0 disables; a positive interval needs<br/>    # an IAM role ARN supplied by the caller (atoms never create dependencies).<br/>    monitoring_interval = optional(number, 60)<br/>    monitoring_role_arn = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false<br/>    allow_deletion    = optional(bool, false) # permit deletion_protection=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the Aurora cluster atom, collected on a single object. |
<!-- END_TF_DOCS -->