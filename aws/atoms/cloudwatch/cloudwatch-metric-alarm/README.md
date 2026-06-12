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
| [aws_cloudwatch_metric_alarm.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for a single CloudWatch metric alarm. All inputs live on this<br/>one object. This atom owns exactly one `aws_cloudwatch_metric_alarm`.<br/><br/>Secure-by-default posture (PCI DSS Req 10.6 — alert on security events):<br/>`treat_missing_data` defaults to "notBreaching" so a quiet metric does not<br/>silently flap, and the caller must supply `alarm_actions` (an SNS topic) for<br/>the alarm to actually notify. Required inputs (alarm\_name, comparison\_operator,<br/>evaluation\_periods) carry no defaults. | <pre>object({<br/>    # --- Required: the caller must decide these. No defaults. ---<br/>    alarm_name          = string<br/>    comparison_operator = string<br/>    evaluation_periods  = number<br/><br/>    # --- The metric being watched. Optional so math/expression alarms remain<br/>    #     possible, but for a standard single-metric alarm all four are needed. ---<br/>    metric_name = optional(string)<br/>    namespace   = optional(string)<br/>    period      = optional(number, 300)<br/>    statistic   = optional(string, "Sum")<br/>    threshold   = optional(number, 1)<br/><br/>    # --- Notification wiring (SNS topic ARNs). ---<br/>    alarm_actions = optional(list(string), [])<br/>    ok_actions    = optional(list(string), [])<br/><br/>    alarm_description   = optional(string)<br/>    dimensions          = optional(map(string), {})<br/>    treat_missing_data  = optional(string, "notBreaching")<br/>    datapoints_to_alarm = optional(number)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the CloudWatch metric alarm atom, collected on a single object. |
<!-- END_TF_DOCS -->