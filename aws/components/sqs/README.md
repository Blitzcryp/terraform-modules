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
| <a name="module_queue"></a> [queue](#module\_queue) | ../../atoms/sqs/sqs-queue | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the sqs component (an encrypted SQS queue with a DLQ). All<br/>inputs live on this single object. PCI-DSS-compliant defaults are baked into<br/>the optional() fields, so passing only the required `name` yields a queue<br/>encrypted at rest with a dedicated CMK, a dead-letter queue, and a policy<br/>denying non-TLS access.<br/><br/>This component composes atoms via module blocks: a kms-key atom (unless a<br/>`kms_key_arn` is supplied) and the sqs-queue atom (which owns its DLQ). | <pre>object({<br/>    # --- Required: the caller must decide the queue name. ---<br/>    name = string<br/><br/>    # --- Encryption (PCI DSS Req 3) ---<br/>    # BYOK: when set, the supplied CMK is used and no kms-key atom is created.<br/>    # When null, a dedicated kms-key atom is created for this queue.<br/>    kms_key_arn = optional(string)<br/><br/>    # FIFO queues require a '.fifo' suffix on the name (validated by the atom).<br/>    fifo_queue = optional(bool, false)<br/><br/>    # --- Dead-letter queue (operational resilience). On by default. ---<br/>    enable_dlq        = optional(bool, true)<br/>    max_receive_count = optional(number, 5)<br/><br/>    # --- Retention ---<br/>    message_retention_seconds = optional(number, 345600) # 4 days<br/><br/>    # --- Queue policy (PCI DSS Req 4) ---<br/>    # The TLS-deny statement is contributed by the sqs-queue atom; extra<br/>    # statements (list of IAM statement objects) are appended here.<br/>    additional_policy_statements = optional(any, [])<br/><br/>    # --- Tagging ---<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the sqs component, collected on a single object. |
<!-- END_TF_DOCS -->