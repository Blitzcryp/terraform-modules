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
| [aws_sns_topic_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for a single SNS topic subscription. All inputs live on this<br/>single object. Defaults favour the secure-by-default posture: raw message<br/>delivery is off and endpoints are NOT auto-confirmed by Terraform.<br/><br/>This atom owns exactly one `aws_sns_topic_subscription`. The topic ARN it<br/>binds to is passed in by reference (a higher layer owns the topic). | <pre>object({<br/>    topic_arn = string # required — the topic this subscription binds to<br/>    protocol  = string # required — sqs | lambda | firehose | application | sms | email | email-json | http | https<br/>    endpoint  = string # required — destination (format depends on protocol)<br/><br/>    # Operational knobs (kept conservative by default).<br/>    raw_message_delivery   = optional(bool, false)<br/>    endpoint_auto_confirms = optional(bool, false)<br/>    filter_policy          = optional(string) # null = no filter<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the SNS subscription atom, collected on a single object. |
<!-- END_TF_DOCS -->