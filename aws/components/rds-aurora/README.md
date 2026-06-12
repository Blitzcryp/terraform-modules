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
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ../../atoms/rds/rds-aurora-cluster | n/a |
| <a name="module_db_subnet_group"></a> [db\_subnet\_group](#module\_db\_subnet\_group) | ../../atoms/rds/db-subnet-group | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../atoms/kms/kms-key | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the rds-aurora component (a provisioned, secure-by-default<br/>Aurora cluster). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked into the optional() fields: storage is encrypted, deletion<br/>protection is on, backups are retained, IAM auth is on, and the master<br/>password is managed in Secrets Manager (never plaintext). The DB security<br/>group has NO public ingress — only the supplied app security groups / CIDRs<br/>may reach the DB port. Required fields (name, vpc\_id, subnet\_ids) have no<br/>default, so config cannot be omitted. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # required — cluster_identifier<br/>    vpc_id     = string       # required — VPC for the DB security group<br/>    subnet_ids = list(string) # required — private subnets for the DB subnet group<br/><br/>    # --- Engine / sizing ---<br/>    engine         = optional(string, "aurora-postgresql")<br/>    instance_count = optional(number, 2)<br/>    instance_class = optional(string, "db.r6g.large")<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # DB-port ingress is allowed ONLY from these app security groups / CIDRs.<br/>    # Empty lists => a DB security group with no ingress at all (most locked-down).<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # Engine-derived default (5432 for postgresql, 3306 for mysql) when null.<br/>    db_port = optional(number)<br/><br/>    # --- Backups (PCI DSS Req 10 / resilience) ---<br/>    backup_retention_period = optional(number, 14) # 7..35<br/><br/>    # Enhanced OS monitoring (PCI DSS Req 10). monitoring_interval defaults to 0<br/>    # because a positive interval requires a caller-supplied monitoring_role_arn<br/>    # (the cluster atom takes the ARN as input — it never creates the role).<br/>    monitoring_interval = optional(number, 0)<br/>    monitoring_role_arn = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false<br/>    allow_deletion    = optional(bool, false) # permit deletion_protection=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the rds-aurora component, collected on a single object. |
<!-- END_TF_DOCS -->