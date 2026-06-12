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
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../atoms/cloudwatch/cloudwatch-log-group | n/a |
| <a name="module_msk_cluster"></a> [msk\_cluster](#module\_msk\_cluster) | ../../atoms/msk/msk-cluster | n/a |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../atoms/vpc/security-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the kafka (Amazon MSK) component. All inputs live on this<br/>single object. PCI-DSS-compliant defaults are baked into the optional()<br/>fields, so the caller only has to supply the required `name`, `vpc_id` and<br/>`client_subnets`. The component composes a private broker security group, a<br/>customer-managed CMK (unless a BYO key is supplied), a KMS-encrypted broker<br/>log group, and an MSK cluster with TLS in transit, CMK at rest, SASL/IAM<br/>auth and broker logging. Insecure choices stay in the underlying atoms behind<br/>their own `allow_*` escape hatches. | <pre>object({<br/>    # --- Required: the caller must decide these ---<br/>    name           = string       # cluster name; also basis for SG/KMS/log-group names<br/>    vpc_id         = string       # VPC the broker SG lives in<br/>    client_subnets = list(string) # subnets the brokers are placed in<br/><br/>    # --- Cluster shape (secure defaults) ---<br/>    kafka_version          = optional(string, "3.6.0")<br/>    number_of_broker_nodes = optional(number, 3)<br/>    broker_instance_type   = optional(string, "kafka.m5.large")<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    kms_key_arn = optional(string) # BYOK: if set, no kms-key atom is created<br/><br/>    # --- Broker SG ingress (PCI DSS Req 1: no public ingress) ---<br/>    # Clients are admitted on the Kafka TLS ports only, by referenced SG or CIDR.<br/>    allowed_security_group_ids = optional(list(string), [])<br/>    allowed_cidrs              = optional(list(string), [])<br/><br/>    # --- Broker logging (PCI DSS Req 10) ---<br/>    log_retention_days = optional(number, 365) # >= 1 year of audit logs<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the kafka (Amazon MSK) component, collected on a single object. |
<!-- END_TF_DOCS -->