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
| [aws_elasticache_replication_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the ElastiCache (Redis) replication group. All inputs live on<br/>this single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields: encryption at rest is on (PCI Req 3), encryption in transit is on<br/>(PCI Req 4), automatic failover and Multi-AZ are on, and snapshots are retained.<br/>Insecure choices require flipping an explicit `allow_*` escape hatch.<br/><br/>PCI DSS Req 8: config.auth\_token must come from a secrets manager — never a<br/>literal. The whole variable is marked sensitive because it carries the token. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    replication_group_id = string       # required — identifier (stored lowercase)<br/>    subnet_group_name    = string       # required — cache subnet group name<br/>    security_group_ids   = list(string) # required — VPC security group IDs<br/><br/>    description = optional(string, "Managed by terraform (atoms/elasticache/elasticache-replication-group)")<br/><br/>    # --- Engine / sizing ---<br/>    engine               = optional(string, "redis")<br/>    engine_version       = optional(string, "7.1")<br/>    node_type            = optional(string, "cache.t4g.medium")<br/>    port                 = optional(number, 6379)<br/>    parameter_group_name = optional(string) # null = engine-specific default group<br/><br/>    # --- Topology / resilience ---<br/>    automatic_failover_enabled = optional(bool, true)<br/>    multi_az_enabled           = optional(bool, true)<br/>    num_cache_clusters         = optional(number, 2) # >1 so automatic failover is possible<br/>    snapshot_retention_limit   = optional(number, 7)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    at_rest_encryption_enabled = optional(bool, true)<br/>    kms_key_arn                = optional(string) # CMK; null = AWS-managed key<br/><br/>    # --- Encryption in transit (PCI DSS Req 4) ---<br/>    transit_encryption_enabled = optional(bool, true)<br/><br/>    # --- Access control (PCI DSS Req 8) ---<br/>    # SECURITY: supply from a secrets manager, never a literal. Recommended when<br/>    # transit encryption is on. Requires transit_encryption_enabled = true.<br/>    auth_token = optional(string)<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    allow_unencrypted_at_rest  = optional(bool, false) # permit at_rest_encryption_enabled = false<br/>    allow_plaintext_in_transit = optional(bool, false) # permit transit_encryption_enabled = false<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the ElastiCache replication group atom, collected on a single object. |
<!-- END_TF_DOCS -->