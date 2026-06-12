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
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the standalone RDS instance. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields, so<br/>passing only the required fields yields a compliant instance: encrypted at<br/>rest, Multi-AZ, deletion protection on, 14-day backups, IAM auth on, the<br/>master password managed in Secrets Manager (never plaintext), Performance<br/>Insights on, and not publicly accessible. Insecure choices require flipping an<br/>explicit `allow_*` escape hatch (grep-able, auditable). | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    identifier             = string       # required — DB identifier<br/>    engine                 = string       # required — e.g. postgres | mysql | mariadb<br/>    db_subnet_group_name   = string       # required — where the instance lives<br/>    vpc_security_group_ids = list(string) # required — network exposure<br/><br/>    # --- Engine / sizing ---<br/>    engine_version        = optional(string)<br/>    instance_class        = optional(string, "db.t3.medium")<br/>    allocated_storage     = optional(number, 20)<br/>    max_allocated_storage = optional(number, 100) # storage autoscaling ceiling<br/><br/>    # --- Encryption at rest (PCI DSS Req 3: protect stored data) ---<br/>    # storage_encrypted snapshots inherit the instance's encryption automatically.<br/>    storage_encrypted = optional(bool, true)<br/>    kms_key_arn       = optional(string) # feeds kms_key_id; null = AWS-managed aws/rds key<br/><br/>    # --- High availability / safety ---<br/>    multi_az            = optional(bool, true)<br/>    deletion_protection = optional(bool, true)<br/><br/>    # --- Master credentials (PCI DSS Req 8: authenticate access) ---<br/>    # COMPLIANCE: we NEVER accept a plaintext master_password. Static creds in<br/>    # state/config violate PCI Req 8.2.1 (no clear-text). The password is created<br/>    # and rotated in AWS Secrets Manager via manage_master_user_password.<br/>    manage_master_user_password = optional(bool, true)<br/>    master_username             = optional(string, "dbadmin")<br/><br/>    # --- Authentication (PCI DSS Req 8) ---<br/>    iam_database_authentication_enabled = optional(bool, true)<br/><br/>    # --- Backups (PCI DSS Req 10 / resilience: retained for forensics) ---<br/>    backup_retention_period = optional(number, 14) # 7..35<br/>    copy_tags_to_snapshot   = optional(bool, true)<br/><br/>    # --- Patch hygiene (PCI DSS Req 6) ---<br/>    auto_minor_version_upgrade = optional(bool, true)<br/><br/>    # --- Monitoring (PCI DSS Req 10) ---<br/>    performance_insights_enabled = optional(bool, true)<br/><br/>    # --- Logging (PCI DSS Req 10: audit trails) ---<br/>    # null => engine default log set chosen in main.tf.<br/>    enabled_cloudwatch_logs_exports = optional(list(string))<br/><br/>    # --- Network ---<br/>    publicly_accessible = optional(bool, false)<br/>    port                = optional(number)<br/><br/>    # --- Optional groups ---<br/>    parameter_group_name = optional(string)<br/>    option_group_name    = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false<br/>    allow_deletion    = optional(bool, false) # permit deletion_protection=false<br/>    allow_public      = optional(bool, false) # permit publicly_accessible=true<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the RDS instance atom, collected on a single object. |
<!-- END_TF_DOCS -->