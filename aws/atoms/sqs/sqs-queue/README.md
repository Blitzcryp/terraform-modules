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
| [aws_sqs_queue.dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the SQS queue. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields: encryption<br/>at rest (Req 3) is ALWAYS on — a CMK when supplied, else SSE-SQS as fallback;<br/>a queue policy denying non-TLS access (Req 4) is attached by default; and a<br/>dead-letter queue is created by default. Disabling encryption entirely<br/>requires flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name       = string                # required — no default<br/>    fifo_queue = optional(bool, false) # FIFO queues require a '.fifo' suffix on the name<br/><br/>    # --- Secure-by-default controls ---<br/>    # PCI DSS Req 3: encryption at rest. A CMK ARN takes precedence; when null,<br/>    # SSE-SQS (sqs_managed_sse_enabled) is used so encryption is NEVER off.<br/>    kms_key_arn = optional(string)<br/><br/>    message_retention_seconds = optional(number, 345600) # 4 days<br/><br/>    # Dead-letter queue (operational resilience). On by default.<br/>    enable_dlq        = optional(bool, true)<br/>    max_receive_count = optional(number, 5)<br/><br/>    # PCI DSS Req 4: a default policy denies any access over a non-TLS transport.<br/>    # Extra statements (list of IAM statement objects) may be appended here.<br/>    additional_policy_statements = optional(any, [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # ESCAPE HATCH: disable BOTH KMS and SSE-SQS, leaving the queue unencrypted.<br/>    # Requires a documented PCI exception (security@emag.ro).<br/>    allow_unencrypted = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the SQS queue atom, collected on a single object. |
<!-- END_TF_DOCS -->