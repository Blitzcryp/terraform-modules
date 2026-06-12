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
| [aws_cloudwatch_log_metric_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for a single CloudWatch Logs metric filter. All inputs live on<br/>this one object. This atom owns exactly one `aws_cloudwatch_log_metric_filter`.<br/><br/>A metric filter extracts a numeric metric from log events matching `pattern`<br/>(typically the CloudTrail->CloudWatch Logs group). Pairing it with a<br/>cloudwatch-metric-alarm implements PCI DSS Req 10.6 (alert on security events).<br/><br/>NOTE on tags: `aws_cloudwatch_log_metric_filter` is NOT a taggable resource.<br/>`tags` is accepted here only for interface uniformity with the rest of the<br/>library and is intentionally not applied to any resource. | <pre>object({<br/>    # --- Required: the caller must decide these. No defaults. ---<br/>    name           = string<br/>    log_group_name = string<br/>    pattern        = string<br/>    metric_name    = string<br/><br/>    # --- The metric transformation. CISBenchmark namespace + value "1" matches<br/>    #     the CIS AWS Foundations monitoring recipe (count of matching events). ---<br/>    metric_namespace = optional(string, "CISBenchmark")<br/>    metric_value     = optional(string, "1")<br/>    default_value    = optional(number) # null = no value emitted on non-match<br/><br/>    # Accepted for interface uniformity only; NOT applied (resource is untaggable).<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CloudWatch log metric filter atom, collected on a single object. |
<!-- END_TF_DOCS -->