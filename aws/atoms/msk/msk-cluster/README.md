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
| [aws_msk_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/msk_cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the Amazon MSK (Managed Streaming for Apache Kafka) cluster.<br/>All inputs live on this single object. PCI-DSS-compliant defaults are baked<br/>into the optional() fields, so passing only the required fields yields a<br/>compliant cluster: encrypted at rest, TLS in transit + in-cluster, SASL/IAM<br/>auth, broker logs to CloudWatch. Insecure choices require flipping an explicit<br/>`allow_*` escape hatch (grep-able, audit-friendly). | <pre>object({<br/>    cluster_name = string # required<br/><br/>    # --- Cluster shape ---<br/>    kafka_version          = optional(string, "3.6.0")<br/>    number_of_broker_nodes = optional(number, 3)<br/>    broker_instance_type   = optional(string, "kafka.m5.large")<br/>    client_subnets         = list(string) # required<br/>    security_groups        = list(string) # required<br/>    ebs_volume_size        = optional(number, 100)<br/><br/>    # --- Encryption at rest (PCI DSS Req 3) ---<br/>    kms_key_arn = optional(string) # null = AWS-managed MSK key (still encrypted)<br/>    # ESCAPE HATCH: there is no way to disable MSK at-rest encryption (AWS always<br/>    # encrypts), this flag documents an intentional reliance on the AWS-managed key<br/>    # instead of a customer-managed CMK. Requires a documented exception.<br/>    allow_unencrypted_at_rest = optional(bool, false)<br/><br/>    # --- Encryption in transit (PCI DSS Req 4) ---<br/>    # client_broker is forced to TLS unless allow_plaintext_in_transit=true.<br/>    encryption_in_transit_client_broker = optional(string, "TLS")<br/>    in_cluster_encryption               = optional(bool, true)<br/>    # ESCAPE HATCH: permit TLS_PLAINTEXT / PLAINTEXT on client_broker.<br/>    allow_plaintext_in_transit = optional(bool, false)<br/><br/>    # --- Client authentication (PCI DSS Req 7/8) ---<br/>    sasl_iam_enabled   = optional(bool, true) # secure default<br/>    sasl_scram_enabled = optional(bool, false)<br/>    tls_auth_enabled   = optional(bool, false)<br/><br/>    # --- Monitoring (PCI DSS Req 10) ---<br/>    enhanced_monitoring = optional(string, "PER_TOPIC_PER_BROKER")<br/>    open_monitoring     = optional(bool, false) # Prometheus JMX + node exporters<br/><br/>    # --- Broker logging to CloudWatch (PCI DSS Req 10) ---<br/>    cloudwatch_log_group_name = optional(string) # provide to enable broker logs<br/>    # ESCAPE HATCH: permit running with broker logging disabled.<br/>    allow_logging_disabled = optional(bool, false)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the MSK cluster atom, collected on a single object. |
<!-- END_TF_DOCS -->