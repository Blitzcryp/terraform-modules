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
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the EventBridge rule atom (aws\_cloudwatch\_event\_rule).<br/>All inputs live on this single object. A rule matches events either by an<br/>event pattern OR a schedule expression — exactly one must be supplied. The<br/>rule defaults to ENABLED so it starts routing immediately. | <pre>object({<br/>    name        = string           # required — no default<br/>    description = optional(string) # null = no description<br/><br/>    # Exactly one of these two must be set (validated below).<br/>    event_pattern       = optional(string) # JSON string selecting matching events<br/>    schedule_expression = optional(string) # rate(...) / cron(...) expression<br/><br/>    # Operational state of the rule.<br/>    state = optional(string, "ENABLED")<br/><br/>    # Bus the rule attaches to. null = the account default event bus.<br/>    event_bus_name = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the EventBridge rule atom, collected on a single object. |
<!-- END_TF_DOCS -->