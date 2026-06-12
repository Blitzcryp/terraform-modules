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
| <a name="module_metric_alarm"></a> [metric\_alarm](#module\_metric\_alarm) | ../../atoms/cloudwatch/cloudwatch-metric-alarm | n/a |
| <a name="module_metric_filter"></a> [metric\_filter](#module\_metric\_filter) | ../../atoms/cloudwatch/cloudwatch-log-metric-filter | n/a |
| <a name="module_topic"></a> [topic](#module\_topic) | ../../atoms/sns/sns-topic | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the cloudwatch-alarms component: the CIS AWS Foundations /<br/>PCI DSS Req 10 monitoring & alerting baseline (Req 10.6 — alert on security<br/>events). It reads the CloudTrail->CloudWatch Logs group and, for each security<br/>event in the curated baseline, creates a log metric filter plus a metric alarm<br/>that notifies an SNS topic.<br/><br/>All inputs live on this single object. PCI-compliant defaults are baked into<br/>the optional() fields: passing only the required `name_prefix` and<br/>`cloudtrail_log_group_name` provisions the FULL baseline alarm set, an<br/>encrypted SNS topic (with a dedicated CMK), and wires every alarm to it.<br/><br/>This component composes atoms via module blocks ONLY:<br/>cloudwatch/cloudwatch-log-metric-filter (N), cloudwatch/cloudwatch-metric-alarm<br/>(N), and — unless a BYO `sns_topic_arn` is supplied — sns/sns-topic and<br/>kms/kms-key. | <pre>object({<br/>    # --- Required: the caller must decide these. No defaults. ---<br/>    # Base name for created resources (SNS topic, CMK alias, alarm/filter names).<br/>    name_prefix = string<br/>    # The CloudTrail -> CloudWatch Logs log group the metric filters read from.<br/>    cloudtrail_log_group_name = string<br/><br/>    # BYO SNS topic ARN for alarm notifications. null = this component creates an<br/>    # encrypted topic (PCI DSS Req 3/4) and a dedicated CMK (unless kms_key_arn set).<br/>    sns_topic_arn = optional(string)<br/><br/>    # BYO CMK ARN for the created SNS topic. null + no sns_topic_arn = create one.<br/>    kms_key_arn = optional(string)<br/><br/>    # Subset of baseline alarm keys to enable. null/empty = enable ALL baseline<br/>    # alarms (the secure default — full CIS/PCI Req 10 monitoring coverage).<br/>    enabled_alarms = optional(list(string))<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the cloudwatch-alarms component, collected on a single object. |
<!-- END_TF_DOCS -->