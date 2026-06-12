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
| <a name="module_inspector"></a> [inspector](#module\_inspector) | ../../atoms/inspector/inspector2-enabler | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_notification_topic"></a> [notification\_topic](#module\_notification\_topic) | ../../atoms/sns/sns-topic | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the inspector component (account-level vulnerability<br/>scanning plus a findings-notification SNS topic). All inputs live on this<br/>single object. PCI-compliant defaults are baked into the optional() fields,<br/>so passing `{}` (or omitting config) enables continuous Inspector v2 scanning<br/>for ECR, EC2 and Lambda (Req 6 & 11) and creates a CMK-encrypted SNS topic<br/>(Req 3 & 4) for findings notifications.<br/><br/>NOTE: routing Inspector findings to the SNS topic requires an EventBridge<br/>rule. There is no EventBridge atom in this library yet, so this component<br/>only EXPOSES the topic ARN in its manifest; a future EventBridge component<br/>must wire Inspector findings -> this topic. No raw resources are added here. | <pre>object({<br/>    # PCI DSS Req 6/11: resource types Inspector scans for vulnerabilities.<br/>    resource_types = optional(list(string), ["ECR", "EC2", "LAMBDA"])<br/><br/>    # --- Secure-by-default controls (PCI DSS Req 3 encryption) ---<br/>    # BYO CMK for the SNS topic. null = this component creates one.<br/>    kms_key_arn = optional(string)<br/>    # Whether to create the findings-notification SNS topic.<br/>    create_notification_topic = optional(bool, true)<br/><br/>    tags = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the inspector component, collected on a single object. |
<!-- END_TF_DOCS -->