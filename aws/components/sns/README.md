<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.60 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../../atoms/kms/kms-key | n/a |
| <a name="module_subscription"></a> [subscription](#module\_subscription) | ../../atoms/sns/sns-subscription | n/a |
| <a name="module_topic"></a> [topic](#module\_topic) | ../../atoms/sns/sns-topic | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the sns component (an encrypted SNS topic). All inputs live<br/>on this single object. PCI-DSS-compliant defaults are baked into the<br/>optional() fields, so passing only the required `name` yields a topic that is<br/>encrypted at rest with a dedicated CMK and carries a policy denying non-TLS<br/>publish.<br/><br/>This component composes atoms via module blocks: a kms-key atom (unless a<br/>`kms_key_arn` is supplied), the sns-topic atom, and one sns-subscription atom<br/>per entry in `subscriptions`. | <pre>object({<br/>    # --- Required: the caller must decide the topic name. ---<br/>    name = string<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYOK: when set, the supplied CMK is used and no kms-key atom is created.<br/>    # When null, a dedicated kms-key atom is created for this topic.<br/>    kms_key_arn = optional(string)<br/><br/>    # FIFO topics require a '.fifo' suffix on the name (validated by the atom).<br/>    fifo_topic = optional(bool, false)<br/><br/>    # --- Topic policy (PCI DSS Req 4) ---<br/>    # The TLS-deny statement is contributed by the sns-topic atom; extra<br/>    # statements (list of IAM statement objects) are appended here.<br/>    additional_policy_statements = optional(any, [])<br/><br/>    # --- Subscriptions ---<br/>    # Each entry creates one sns-subscription atom bound to this topic.<br/>    subscriptions = optional(list(object({<br/>      protocol = string<br/>      endpoint = string<br/>    })), [])<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the sns component, collected on a single object. |
<!-- END_TF_DOCS -->