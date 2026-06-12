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
| <a name="module_db_subnet_group"></a> [db\_subnet\_group](#module\_db\_subnet\_group) | ../../atoms/rds/db-subnet-group | n/a |
| <a name="module_instance"></a> [instance](#module\_instance) | ../../atoms/rds/rds-instance | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../atoms/kms/kms-key | n/a |
| <a name="module_parameter_group"></a> [parameter\_group](#module\_parameter\_group) | ../../atoms/rds/rds-parameter-group | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the rds-instance component (a standalone, secure-by-default<br/>RDS database). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked into the optional() fields: storage is encrypted, the<br/>instance is Multi-AZ, deletion protection is on, backups are retained, IAM<br/>auth is on, and the master password is managed in Secrets Manager (never<br/>plaintext). The DB security group has NO public ingress — only the supplied<br/>app security groups / CIDRs may reach the DB port. Required fields (name,<br/>vpc\_id, subnet\_ids) have no default, so config cannot be omitted. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # required — DB identifier<br/>    vpc_id     = string       # required — VPC for the DB security group<br/>    subnet_ids = list(string) # required — private subnets for the DB subnet group<br/><br/>    # --- Engine / sizing ---<br/>    engine            = optional(string, "postgres")<br/>    engine_version    = optional(string)<br/>    instance_class    = optional(string, "db.t3.medium")<br/>    allocated_storage = optional(number, 20)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # DB-port ingress is allowed ONLY from these app security groups / CIDRs.<br/>    # Empty lists => a DB security group with no ingress at all (most locked-down).<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # Engine-derived default (5432 for postgres, 3306 for mysql/mariadb) when null.<br/>    db_port = optional(number)<br/><br/>    # --- Parameter group (created only when parameters is non-empty) ---<br/>    parameters = optional(list(object({<br/>      name         = string<br/>      value        = string<br/>      apply_method = optional(string, "immediate")<br/>    })), [])<br/>    parameter_group_family = optional(string) # required when parameters is non-empty<br/><br/>    # --- Backups (PCI DSS Req 10 / resilience) ---<br/>    backup_retention_period = optional(number, 14) # 7..35<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false<br/>    allow_deletion    = optional(bool, false) # permit deletion_protection=false<br/>    allow_public      = optional(bool, false) # permit publicly_accessible=true<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the rds-instance component, collected on a single object. |
<!-- END_TF_DOCS -->