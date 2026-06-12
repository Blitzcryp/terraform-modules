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
| <a name="module_domain"></a> [domain](#module\_domain) | ../../atoms/opensearch/opensearch-domain | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the opensearch component (a VPC-placed, secure-by-default<br/>OpenSearch domain with audit/slow-log delivery). All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields: the domain is encrypted at rest with a dedicated CMK, node-to-node<br/>encryption is on, HTTPS is enforced on TLS 1.2, and fine-grained access<br/>control is on with an IAM master user. The domain security group has NO<br/>public ingress — only the supplied client security groups / CIDRs may reach<br/>HTTPS (443). Audit + slow logs are published to a CMK-encrypted CloudWatch<br/>log group. Required fields (name, vpc\_id, subnet\_ids) have no default, so<br/>config cannot be omitted.<br/><br/>Note: the CloudWatch Logs resource policy that lets es.amazonaws.com write to<br/>the log group is an account-level concern (set once per account/region) and<br/>is intentionally not created here — this component composes atoms only. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name       = string       # required — the OpenSearch domain name<br/>    vpc_id     = string       # required — VPC for the domain security group<br/>    subnet_ids = list(string) # required — private subnets for VPC placement<br/><br/>    # --- Engine / sizing ---<br/>    engine_version = optional(string, "OpenSearch_2.11")<br/>    instance_type  = optional(string, "t3.small.search")<br/>    instance_count = optional(number, 2)<br/>    volume_size    = optional(number, 20) # EBS GiB per data node<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    # BYO CMK ARN; when null the component creates a dedicated KMS key.<br/>    kms_key_arn = optional(string)<br/><br/>    # --- Network exposure (PCI DSS Req 1) ---<br/>    # HTTPS (443) ingress is allowed ONLY from these client security groups /<br/>    # CIDRs. Empty lists => a domain security group with no ingress at all.<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # --- Fine-grained access control (PCI DSS Req 7/8) ---<br/>    # IAM master role ARN; null still enables FGAC with the internal user<br/>    # database disabled (no stored password).<br/>    master_user_arn = optional(string)<br/><br/>    # --- Audit / slow-log retention (PCI DSS Req 10) ---<br/>    log_retention_days = optional(number, 365) # >= 1 year of audit logs<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the opensearch component, collected on a single object. |
<!-- END_TF_DOCS -->