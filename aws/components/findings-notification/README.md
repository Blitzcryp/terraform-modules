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
| <a name="module_rule"></a> [rule](#module\_rule) | ../../atoms/eventbridge/event-rule | n/a |
| <a name="module_target"></a> [target](#module\_target) | ../../atoms/eventbridge/event-target | n/a |
| <a name="module_topic"></a> [topic](#module\_topic) | ../../atoms/sns/sns-topic | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the findings-notification component: routes AWS security<br/>findings to an encrypted SNS topic via EventBridge. Closes the<br/>Inspector/GuardDuty/Security Hub -> SNS gap.<br/><br/>All inputs live on this single object. PCI-compliant defaults are baked into<br/>the optional() fields: passing only the required `name` creates a CMK<br/>(KMS-encrypted, rotation on), a KMS-encrypted SNS topic that denies non-TLS<br/>publish and allows EventBridge to publish, an EventBridge rule matching ALL<br/>supported finding sources, and a target wiring that rule to the topic.<br/><br/>This component composes atoms via module blocks ONLY: kms/kms-key (unless a<br/>BYO `kms_key_arn` is supplied), sns/sns-topic, eventbridge/event-rule and<br/>eventbridge/event-target. | <pre>object({<br/>    # --- Required: the caller must decide the base name. ---<br/>    name = string<br/><br/>    # Which security service's findings to route. "all" routes Security Hub,<br/>    # Inspector and GuardDuty findings. Build the event pattern accordingly.<br/>    source = optional(string, "all")<br/><br/>    # BYO CMK for the SNS topic. null = this component creates one with a key<br/>    # policy allowing EventBridge to use it (PCI DSS Req 3 encryption at rest).<br/>    kms_key_arn = optional(string)<br/><br/>    # Escape hatch / advanced: a full event_pattern JSON string that OVERRIDES<br/>    # the source-derived pattern. null = derive the pattern from `source`.<br/>    additional_event_pattern = optional(string)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the findings-notification component, collected on a single object. |
<!-- END_TF_DOCS -->