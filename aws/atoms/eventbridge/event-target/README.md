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
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the EventBridge target atom (aws\_cloudwatch\_event\_target).<br/>All inputs live on this single object. A target binds an EventBridge rule to<br/>a destination ARN (SNS topic, Lambda, SQS queue, ...).<br/><br/>NOTE on tags: aws\_cloudwatch\_event\_target has NO tags argument. The `tags`<br/>field is accepted here only for uniformity with the rest of the library<br/>(every atom takes config.tags) and is intentionally NOT applied to any<br/>resource. It is therefore a no-op for this atom. | <pre>object({<br/>    rule = string # required — name of the EventBridge rule this target attaches to<br/>    arn  = string # required — ARN of the destination (SNS topic, Lambda, SQS, ...)<br/><br/>    target_id      = optional(string) # null = provider-generated unique id<br/>    event_bus_name = optional(string) # must match the rule's bus; null = default bus<br/>    role_arn       = optional(string) # IAM role EventBridge assumes (for some targets)<br/><br/>    # Supply at most one of input / input_path (validated below).<br/>    input      = optional(string) # constant JSON text passed to the target<br/>    input_path = optional(string) # JSONPath extracting part of the event<br/><br/>    # Accepted for uniformity only; NOT applied (resource has no tags). See above.<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the EventBridge target atom, collected on a single object. |
<!-- END_TF_DOCS -->