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
| <a name="input_config"></a> [config](#input\_config) | Configuration for the rds-aurora-serverless component (a secure-by-default<br/>Aurora Serverless v2 cluster). Same composition and config as the rds-aurora<br/>component, but instead of instance\_class it exposes min\_capacity / max\_capacity<br/>(Aurora Capacity Units) and forces instances onto db.serverless via the cluster<br/>atom's serverlessv2\_scaling\_configuration. All inputs live on this single<br/>object. PCI-DSS-compliant defaults are baked into the optional() fields:<br/>storage is encrypted, deletion protection is on, backups are retained, IAM<br/>auth is on, and the master password is managed in Secrets Manager (never<br/>plaintext). The DB security group has NO public ingress — only the supplied<br/>app security groups / CIDRs may reach the DB port. Required fields (name,<br/>vpc\_id, subnet\_ids) have no default, so config cannot be omitted. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # required — cluster_identifier<br/>    vpc_id     = string       # required — VPC for the DB security group<br/>    subnet_ids = list(string) # required — private subnets for the DB subnet group<br/><br/>    # --- Engine / sizing (Serverless v2 capacity in ACUs) ---<br/>    engine         = optional(string, "aurora-postgresql")<br/>    instance_count = optional(number, 2)<br/>    min_capacity   = optional(number, 0.5)<br/>    max_capacity   = optional(number, 4)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # DB-port ingress is allowed ONLY from these app security groups / CIDRs.<br/>    # Empty lists => a DB security group with no ingress at all (most locked-down).<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # Engine-derived default (5432 for postgresql, 3306 for mysql) when null.<br/>    db_port = optional(number)<br/><br/>    # --- Backups (PCI DSS Req 10 / resilience) ---<br/>    backup_retention_period = optional(number, 14) # 7..35<br/><br/>    # Enhanced OS monitoring (PCI DSS Req 10). monitoring_interval defaults to 0<br/>    # because a positive interval requires a caller-supplied monitoring_role_arn<br/>    # (the cluster atom takes the ARN as input — it never creates the role).<br/>    monitoring_interval = optional(number, 0)<br/>    monitoring_role_arn = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted = optional(bool, false) # permit storage_encrypted=false<br/>    allow_deletion    = optional(bool, false) # permit deletion_protection=false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the rds-aurora-serverless component, collected on a single object. |
<!-- END_TF_DOCS -->