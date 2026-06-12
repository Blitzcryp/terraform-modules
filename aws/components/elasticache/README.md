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
| <a name="module_kms"></a> [kms](#module\_kms) | ../../atoms/kms/kms-key | n/a |
| <a name="module_replication_group"></a> [replication\_group](#module\_replication\_group) | ../../atoms/elasticache/elasticache-replication-group | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |
| <a name="module_subnet_group"></a> [subnet\_group](#module\_subnet\_group) | ../../atoms/elasticache/elasticache-subnet-group | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the elasticache component (a secure-by-default, encrypted<br/>Redis caching tier). All inputs live on this single object. PCI-DSS-compliant<br/>defaults are baked into the optional() fields: encryption at rest (Req 3) and<br/>in transit (Req 4) are on, automatic failover and Multi-AZ are on, and the<br/>cache security group has NO public ingress — only the supplied app security<br/>groups / CIDRs may reach the Redis port (Req 1). Required fields (name, vpc\_id,<br/>subnet\_ids) have no default, so config cannot be omitted.<br/><br/>PCI DSS Req 8: config.auth\_token must come from a secrets manager — never a<br/>literal. The whole variable is marked sensitive because it carries the token. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # required — replication group id + subnet group + SG names<br/>    vpc_id     = string       # required — VPC for the cache security group<br/>    subnet_ids = list(string) # required — private subnets for the cache subnet group<br/><br/>    # --- Engine / sizing ---<br/>    node_type          = optional(string, "cache.t4g.medium")<br/>    num_cache_clusters = optional(number, 2)<br/>    engine_version     = optional(string, "7.1")<br/>    port               = optional(number, 6379)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Access control (PCI DSS Req 8) ---<br/>    # SECURITY: supply from a secrets manager, never a literal.<br/>    auth_token = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # Redis-port ingress is allowed ONLY from these app security groups / CIDRs.<br/>    # Empty lists => a cache security group with no ingress at all (most locked-down).<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the elasticache component, collected on a single object. |
<!-- END_TF_DOCS -->