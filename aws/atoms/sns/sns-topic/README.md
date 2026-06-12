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
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Configuration for the SNS topic. All inputs live on this single object.<br/>PCI-DSS-compliant defaults are baked into the optional() fields: encryption<br/>at rest (Req 3) is on whenever a CMK is supplied, and a topic policy denying<br/>non-TLS publish (Req 4) is attached by default. Insecure choices require<br/>flipping an explicit `allow_*` escape hatch. | <pre>object({<br/>    name       = string                # required — no default<br/>    fifo_topic = optional(bool, false) # FIFO topics require a '.fifo' suffix on the name<br/><br/>    # --- Secure-by-default controls ---<br/>    # PCI DSS Req 3: encryption at rest. Supply a CMK ARN to encrypt the topic.<br/>    kms_key_arn = optional(string) # null = no CMK; only allowed when allow_unencrypted=true<br/><br/>    # PCI DSS Req 4: a default policy denies any Publish over a non-TLS transport.<br/>    # Extra statements (object/list, merged into the policy) may be appended here.<br/>    additional_policy_statements = optional(any, [])<br/><br/>    tags = optional(map(string), {})<br/><br/>    # --- Escape hatches (insecure choices must be explicit & auditable) ---<br/>    # ESCAPE HATCH: permit a topic with no encryption at rest (no CMK).<br/>    # Requires a documented PCI exception (security@emag.ro).<br/>    allow_unencrypted = optional(bool, false)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_manifest"></a> [manifest](#output\_manifest) | All outputs of the SNS topic atom, collected on a single object. |
<!-- END_TF_DOCS -->